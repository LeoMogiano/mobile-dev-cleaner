import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("PlistReader")
struct PlistReaderTests {
    @Test("dictionary reads XML plist correctly")
    func dictionaryXML() throws {
        let tempDir = try TempDirectory()
        defer { tempDir.remove() }

        let plistURL = tempDir.url.appending(path: "test.plist")
        let xmlContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>name</key>
            <string>test</string>
            <key>count</key>
            <integer>42</integer>
        </dict>
        </plist>
        """
        try xmlContent.write(to: plistURL, atomically: true, encoding: .utf8)

        let reader = PlistReader()
        let dict = try reader.dictionary(at: plistURL)

        #expect(dict != nil)
        #expect(dict?["name"] as? String == "test")
        #expect(dict?["count"] as? Int == 42)
    }

    @Test("dictionary returns nil for nonexistent file")
    func dictionaryNonexistent() throws {
        let nonexistent = URL(filePath: "/tmp/nonexistent-\(UUID().uuidString).plist", directoryHint: .notDirectory)

        let reader = PlistReader()
        let dict = try reader.dictionary(at: nonexistent)

        #expect(dict == nil)
    }

    @Test("dictionary throws error for corrupt plist")
    func dictionaryCorrupt() throws {
        let tempDir = try TempDirectory()
        defer { tempDir.remove() }

        let plistURL = tempDir.url.appending(path: "corrupt.plist")
        try "not a plist".write(to: plistURL, atomically: true, encoding: .utf8)

        let reader = PlistReader()
        #expect(throws: Error.self) {
            try reader.dictionary(at: plistURL)
        }
    }

    @Test("string extracts string value from plist")
    func stringFound() throws {
        let tempDir = try TempDirectory()
        defer { tempDir.remove() }

        let plistURL = tempDir.url.appending(path: "test.plist")
        let xmlContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>message</key>
            <string>hello world</string>
        </dict>
        </plist>
        """
        try xmlContent.write(to: plistURL, atomically: true, encoding: .utf8)

        let reader = PlistReader()
        let value = try reader.string(forKey: "message", at: plistURL)

        #expect(value == "hello world")
    }

    @Test("string returns nil for missing key")
    func stringNotFound() throws {
        let tempDir = try TempDirectory()
        defer { tempDir.remove() }

        let plistURL = tempDir.url.appending(path: "test.plist")
        let xmlContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>other</key>
            <string>value</string>
        </dict>
        </plist>
        """
        try xmlContent.write(to: plistURL, atomically: true, encoding: .utf8)

        let reader = PlistReader()
        let value = try reader.string(forKey: "missing", at: plistURL)

        #expect(value == nil)
    }

    @Test("string returns nil for nonexistent file")
    func stringFileNotFound() throws {
        let nonexistent = URL(filePath: "/tmp/nonexistent-\(UUID().uuidString).plist", directoryHint: .notDirectory)

        let reader = PlistReader()
        let value = try reader.string(forKey: "key", at: nonexistent)

        #expect(value == nil)
    }
}
