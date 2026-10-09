import Darwin
import Foundation

/// Allocated (on-disk) size of a tree via `getattrlistbulk(2)`. Skips symlinks, stays on
/// the root's device, counts hardlinks once.
enum DirectoryWalker {
    private static let bufferSize = 256 * 1024

    static func allocatedSize(at url: URL, token: CancellationToken? = nil) throws -> Int64 {
        let path = url.path(percentEncoded: false)
        var st = stat()
        guard lstat(path, &st) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        switch st.st_mode & S_IFMT {
        case S_IFREG: return Int64(st.st_blocks) * 512
        case S_IFDIR: break
        default: return 0
        }
        let rootFD = open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
        guard rootFD >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        return try walk(rootFD: rootFD, rootPath: path, device: UInt32(bitPattern: st.st_dev), token: token)
    }

    // MARK: - Walk

    private struct Frame {
        let fd: Int32
        var pending: [String]
    }

    private struct Totals {
        var size: Int64 = 0
        var seenLinks = Set<UInt64>()
    }

    // Takes ownership of rootFD. Open fds on the stack are bounded by tree depth.
    private static func walk(rootFD: Int32, rootPath: String, device: UInt32, token: CancellationToken?) throws -> Int64 {
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: 8)
        defer { buffer.deallocate() }
        var totals = Totals()
        var stack: [Frame] = []
        defer { for frame in stack { close(frame.fd) } }

        switch try scan(fd: rootFD, buffer: buffer, device: device, totals: &totals, token: token) {
        case .done(let pending):
            stack.append(Frame(fd: rootFD, pending: pending))
        case .unsupported:
            close(rootFD)
            return try fallbackSize(path: rootPath, token: token)
        case .failed(let code):
            close(rootFD)
            throw POSIXError(code)
        }

        while !stack.isEmpty {
            if isCancelled(token) { throw CancellationError() }
            let top = stack.count - 1
            guard let name = stack[top].pending.popLast() else {
                close(stack[top].fd)
                stack.removeLast()
                continue
            }
            let fd = openat(stack[top].fd, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
            guard fd >= 0 else { continue } // EACCES/EPERM or a race: skip silently
            switch try scan(fd: fd, buffer: buffer, device: device, totals: &totals, token: token) {
            case .done(let pending):
                stack.append(Frame(fd: fd, pending: pending))
            case .unsupported:
                if let path = path(of: fd) { totals.size += (try? fallbackSize(path: path, token: token)) ?? 0 }
                close(fd)
            case .failed:
                close(fd)
            }
        }
        return totals.size
    }

    private enum ScanOutcome {
        case done(pending: [String])
        case unsupported
        case failed(POSIXErrorCode)
    }

    private static let objReg: UInt32 = 1
    private static let objDir: UInt32 = 2

    private static func scan(
        fd: Int32, buffer: UnsafeMutableRawPointer, device: UInt32, totals: inout Totals, token: CancellationToken?
    ) throws -> ScanOutcome {
        var list = attrlist()
        list.bitmapcount = UInt16(ATTR_BIT_MAP_COUNT)
        list.commonattr = attrgroup_t(ATTR_CMN_RETURNED_ATTRS) | attrgroup_t(ATTR_CMN_NAME)
            | attrgroup_t(ATTR_CMN_DEVID) | attrgroup_t(ATTR_CMN_OBJTYPE) | attrgroup_t(ATTR_CMN_FILEID)
        list.fileattr = attrgroup_t(ATTR_FILE_LINKCOUNT) | attrgroup_t(ATTR_FILE_ALLOCSIZE)
        let options = UInt64(FSOPT_PACK_INVAL_ATTRS | FSOPT_NOFOLLOW)
        var pending: [String] = []

        while true {
            if isCancelled(token) { throw CancellationError() }
            let count = getattrlistbulk(fd, &list, buffer, bufferSize, options)
            if count < 0 {
                let code = errno
                if code == ENOTSUP || code == EINVAL { return .unsupported }
                return .failed(POSIXErrorCode(rawValue: code) ?? .EIO)
            }
            if count == 0 { return .done(pending: pending) }

            var entry = UnsafeRawPointer(buffer)
            for _ in 0..<Int(count) {
                let length = Int(entry.loadUnaligned(as: UInt32.self))
                parse(entry: entry, device: device, totals: &totals, pending: &pending)
                entry += length
            }
        }
    }

    // Packed layout, no padding: len(4) returned(20) nameref(8) devid(4) objtype(4)
    // fileid(8) [regular files: linkcount(4) allocsize(8)].
    private static func parse(
        entry: UnsafeRawPointer, device: UInt32, totals: inout Totals, pending: inout [String]
    ) {
        var cursor = entry + 4
        let returnedCommon = cursor.loadUnaligned(as: UInt32.self)
        cursor += 20
        guard returnedCommon & UInt32(ATTR_CMN_NAME) != 0 else { return }
        let nameStart = cursor
        let nameOffset = Int(nameStart.loadUnaligned(as: Int32.self))
        cursor += 8
        let devid = cursor.loadUnaligned(as: UInt32.self)
        cursor += 4
        let objType = cursor.loadUnaligned(as: UInt32.self)
        cursor += 4
        let fileID = cursor.loadUnaligned(as: UInt64.self)
        cursor += 8
        guard devid == device else { return }

        if objType == objDir {
            let name = String(cString: (nameStart + nameOffset).assumingMemoryBound(to: CChar.self))
            pending.append(name)
        } else if objType == objReg {
            let linkCount = cursor.loadUnaligned(as: UInt32.self)
            let alloc = cursor.loadUnaligned(fromByteOffset: 4, as: Int64.self)
            if linkCount > 1, !totals.seenLinks.insert(fileID).inserted { return }
            totals.size += alloc
        }
    }

    private static func path(of fd: Int32) -> String? {
        var buf = [CChar](repeating: 0, count: Int(PATH_MAX))
        guard fcntl(fd, F_GETPATH, &buf) == 0 else { return nil }
        let bytes = buf.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    private static func isCancelled(_ token: CancellationToken?) -> Bool {
        Task.isCancelled || token?.isCancelled == true
    }

    // MARK: - Fallback

    // For volumes without getattrlistbulk support.
    private static func fallbackSize(path: String, token: CancellationToken?) throws -> Int64 {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isSymbolicLinkKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: URL(filePath: path), includingPropertiesForKeys: keys, options: [], errorHandler: { _, _ in true }
        ) else { throw POSIXError(.ENOENT) }
        var total: Int64 = 0
        var visited = 0
        for case let item as URL in enumerator {
            visited += 1
            if visited % 512 == 0, isCancelled(token) { throw CancellationError() }
            guard let values = try? item.resourceValues(forKeys: Set(keys)),
                  values.isSymbolicLink != true, values.isRegularFile == true else { continue }
            total += Int64(values.totalFileAllocatedSize ?? 0)
        }
        return total
    }
}

/// Cancellation for walks running outside Swift concurrency (on `SizeCalculator`'s queue).
final class CancellationToken: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool { lock.withLock { cancelled } }

    func cancel() { lock.withLock { cancelled = true } }
}

/// Runs walks on a dedicated, width-limited queue. Walks are long blocking syscalls; on the
/// cooperative pool they starve every other task (small categories would wait for big walks).
final class WalkPool: Sendable {
    static let shared = WalkPool(width: ProcessInfo.processInfo.activeProcessorCount)

    private let queue: OperationQueue

    init(width: Int) {
        let queue = OperationQueue()
        queue.name = "com.mogiteam.mdc.walk"
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = max(1, width)
        self.queue = queue
    }

    func allocatedSize(at url: URL) async throws -> Int64 {
        let token = CancellationToken()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                queue.addOperation {
                    continuation.resume(with: Result { try DirectoryWalker.allocatedSize(at: url, token: token) })
                }
            }
        } onCancel: {
            token.cancel()
        }
    }
}
