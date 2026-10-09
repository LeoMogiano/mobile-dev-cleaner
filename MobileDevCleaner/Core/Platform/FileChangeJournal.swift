import CoreServices
import Foundation

/// Replays the FSEvents history to learn which folders changed since a past event id.
/// A folder's own mtime misses changes deeper in the tree (a build rewriting
/// DerivedData/X/Build/...), so cached sizes are validated against this journal.
enum FileChangeJournal {
    struct Changes: Sendable, Equatable {
        let paths: [String]
        /// False when history was incomplete (dropped events, timeout): trust nothing.
        let isComplete: Bool
    }

    static var currentEventID: UInt64 { FSEventsGetCurrentEventId() }

    static func changes(since eventID: UInt64, under roots: [String], timeout: Duration = .seconds(2)) async -> Changes {
        guard !roots.isEmpty else { return Changes(paths: [], isComplete: true) }
        let collector = Collector()
        return await withCheckedContinuation { continuation in
            collector.onFinish = { continuation.resume(returning: $0) }
            guard collector.start(since: eventID, roots: roots) else {
                collector.finish(complete: false)
                return
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout.timeInterval) {
                collector.finish(complete: false)
            }
        }
    }
}

// FSEvents delivers on its own serial queue; every mutable field is guarded by `lock`.
private final class Collector: @unchecked Sendable {
    var onFinish: ((FileChangeJournal.Changes) -> Void)?
    private var paths: [String] = []
    private var complete = true
    private var finished = false
    private var stream: FSEventStreamRef?
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.mogiteam.mdc.fsevents")

    func start(since eventID: UInt64, roots: [String]) -> Bool {
        var context = FSEventStreamContext(
            version: 0, info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil, release: nil, copyDescription: nil
        )
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer)
        guard let stream = FSEventStreamCreate(
            nil, Collector.callback, &context, roots as CFArray, eventID, 0, flags
        ) else { return false }
        lock.withLock { self.stream = stream }
        FSEventStreamSetDispatchQueue(stream, queue)
        return FSEventStreamStart(stream)
    }

    func record(_ eventPaths: [String], _ flags: [FSEventStreamEventFlags]) {
        let lost = FSEventStreamEventFlags(
            kFSEventStreamEventFlagUserDropped | kFSEventStreamEventFlagKernelDropped
                | kFSEventStreamEventFlagEventIdsWrapped | kFSEventStreamEventFlagRootChanged
        )
        var done = false
        lock.withLock {
            guard !finished else { return }
            for (path, flag) in zip(eventPaths, flags) {
                if flag & FSEventStreamEventFlags(kFSEventStreamEventFlagHistoryDone) != 0 {
                    done = true
                } else if flag & lost != 0 {
                    complete = false
                } else {
                    paths.append(path)
                }
            }
        }
        if done { finish(complete: true) }
    }

    func finish(complete isComplete: Bool) {
        let (result, stream): (FileChangeJournal.Changes?, FSEventStreamRef?) = lock.withLock {
            guard !finished else { return (nil, nil) }
            finished = true
            defer { self.stream = nil }
            return (FileChangeJournal.Changes(paths: paths, isComplete: complete && isComplete), self.stream)
        }
        guard let result else { return }
        // Torn down on the stream's queue (never inside its callback); `self` stays alive until then.
        if let stream {
            nonisolated(unsafe) let stream = stream
            queue.async { [self] in
                FSEventStreamStop(stream)
                FSEventStreamInvalidate(stream)
                FSEventStreamRelease(stream)
                _ = self
            }
        }
        onFinish?(result)
    }

    private static let callback: FSEventStreamCallback = { _, info, count, eventPaths, eventFlags, _ in
        guard let info else { return }
        let collector = Unmanaged<Collector>.fromOpaque(info).takeUnretainedValue()
        let paths = (unsafeBitCast(eventPaths, to: NSArray.self) as? [String]) ?? []
        let flags = Array(UnsafeBufferPointer(start: eventFlags, count: count))
        collector.record(paths, flags)
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = components
        return TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18
    }
}
