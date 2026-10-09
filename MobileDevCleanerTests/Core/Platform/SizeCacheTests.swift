import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("SizeCache")
struct SizeCacheTests {
    @Test("A change deep in a tree invalidates its cached ancestors")
    func invalidatesAncestors() {
        var cache = SizeCache()
        cache.set("/u/Library/Developer/Xcode/DerivedData/App-abc", size: 10, mtime: 1)
        cache.set("/u/.gradle/caches", size: 20, mtime: 1)

        cache.invalidate(changedPaths: ["/u/Library/Developer/Xcode/DerivedData/App-abc/Build/Products/Debug"])

        #expect(cache.lookup("/u/Library/Developer/Xcode/DerivedData/App-abc", mtime: 1) == nil)
        #expect(cache.lookup("/u/.gradle/caches", mtime: 1) == 20)
    }

    @Test("A change at a folder invalidates entries below it")
    func invalidatesDescendants() {
        var cache = SizeCache()
        cache.set("/u/.gradle/caches/transforms-4", size: 5, mtime: 1)

        cache.invalidate(changedPaths: ["/u/.gradle/"])

        #expect(cache.entries.isEmpty)
    }

    @Test("Sibling paths sharing a prefix are kept")
    func keepsSiblings() {
        var cache = SizeCache()
        cache.set("/u/.gradle/caches-old", size: 5, mtime: 1)

        cache.invalidate(changedPaths: ["/u/.gradle/caches"])

        #expect(cache.lookup("/u/.gradle/caches-old", mtime: 1) == 5)
    }

    @Test("Event id survives a save and load round trip")
    func persistsEventID() throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        var cache = SizeCache()
        cache.eventID = 42
        cache.set("/a", size: 1, mtime: 2)
        let file = temp.url.appending(path: "sizes.json")

        try cache.save(to: file)
        let loaded = SizeCache.load(from: file)

        #expect(loaded.eventID == 42)
        #expect(loaded.lookup("/a", mtime: 2) == 1)
    }
}
