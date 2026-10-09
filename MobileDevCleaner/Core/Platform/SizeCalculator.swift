import Foundation

protocol SizeCalculating: Sendable {
    /// Allocated size; served from the persistent cache while the mtime of `url` is unchanged.
    func size(of url: URL) async throws -> Int64
    /// Measures in parallel with bounded concurrency. Missing URLs are omitted from the result.
    func sizes(of urls: [URL]) async -> [URL: Int64]
    func invalidate(_ urls: [URL]) async
    func clearCache() async
    /// Size in bytes of the cache file on disk.
    func cacheFootprint() async -> Int64
    /// Writes the cache to disk if dirty; call when a scan finishes.
    func flush() async
}

actor SizeCalculator: SizeCalculating {
    private struct InFlight {
        let task: Task<Int64, Error>
        var waiters: Int
    }

    private let cacheURL: URL?
    private let maxConcurrency: Int
    private var cache = SizeCache()
    private var isLoaded = false
    private var dirty = false
    private var inFlight: [String: InFlight] = [:]

    init(cacheURL: URL?, maxConcurrency: Int = ProcessInfo.processInfo.activeProcessorCount) {
        self.cacheURL = cacheURL
        self.maxConcurrency = max(1, maxConcurrency)
    }

    func size(of url: URL) async throws -> Int64 {
        let path = url.path(percentEncoded: false)
        // Read before walking so a change during the walk invalidates on the next call.
        let mtime = try Self.mtime(of: path)
        ensureLoaded()
        if let hit = cache.lookup(path, mtime: mtime) { return hit }

        if inFlight[path] != nil {
            inFlight[path]?.waiters += 1
        } else {
            let task = Task.detached(priority: .userInitiated) { [self] in
                let id = Signposts.size.makeSignpostID()
                let state = Signposts.size.beginInterval("measure", id: id)
                defer { Signposts.size.endInterval("measure", state) }
                do {
                    let size = try DirectoryWalker.allocatedSize(at: url)
                    await finish(path: path, size: size, mtime: mtime)
                    return size
                } catch {
                    await finish(path: path, size: nil, mtime: mtime)
                    throw error
                }
            }
            inFlight[path] = InFlight(task: task, waiters: 1)
        }
        guard let task = inFlight[path]?.task else { throw CancellationError() }
        // The shared walk is cancelled only when every waiter has cancelled.
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            Task { await self.release(path) }
        }
    }

    func sizes(of urls: [URL]) async -> [URL: Int64] {
        let limit = maxConcurrency
        return await withTaskGroup(of: (URL, Int64?).self) { group in
            var result: [URL: Int64] = [:]
            var running = 0
            for url in urls {
                if running >= limit, let (u, s) = await group.next() {
                    running -= 1
                    if let s { result[u] = s }
                }
                running += 1
                group.addTask { (url, try? await self.size(of: url)) }
            }
            for await (u, s) in group { if let s { result[u] = s } }
            return result
        }
    }

    func invalidate(_ urls: [URL]) async {
        ensureLoaded()
        for url in urls { cache.remove(url.path(percentEncoded: false)) }
        dirty = true
    }

    func clearCache() async {
        isLoaded = true
        cache.removeAll()
        if let cacheURL { try? FileManager.default.removeItem(at: cacheURL) }
        dirty = false
    }

    func cacheFootprint() async -> Int64 {
        guard let cacheURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: cacheURL.path(percentEncoded: false)),
              let size = attrs[.size] as? NSNumber else { return 0 }
        return size.int64Value
    }

    func flush() async {
        guard dirty, let cacheURL else { return }
        do {
            try cache.save(to: cacheURL)
            dirty = false
        } catch {
            // The cache is only an optimization; a failed save is not fatal.
        }
    }

    // MARK: - Private

    private func ensureLoaded() {
        guard !isLoaded else { return }
        isLoaded = true
        if let cacheURL { cache = SizeCache.load(from: cacheURL) }
    }

    private func finish(path: String, size: Int64?, mtime: Double) {
        inFlight[path] = nil
        guard let size else { return }
        ensureLoaded()
        cache.set(path, size: size, mtime: mtime)
        dirty = true
    }

    private func release(_ path: String) {
        guard var entry = inFlight[path] else { return }
        entry.waiters -= 1
        inFlight[path] = entry
        if entry.waiters <= 0 { entry.task.cancel() }
    }

    private static func mtime(of path: String) throws -> Double {
        var st = stat()
        guard lstat(path, &st) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        return Double(st.st_mtimespec.tv_sec) + Double(st.st_mtimespec.tv_nsec) / 1_000_000_000
    }
}
