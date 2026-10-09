import Foundation

protocol PlistReading: Sendable {
    /// Reads XML or binary plist. Nonexistent file returns nil.
    func dictionary(at url: URL) throws -> [String: any Sendable]?
    func string(forKey key: String, at url: URL) throws -> String?
}

struct PlistReader: PlistReading {
    func dictionary(at url: URL) throws -> [String: any Sendable]? {
        do {
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )

            guard let rawDict = plist as? [String: Any] else {
                return nil
            }

            // PropertyListSerialization guarantees plist values are Sendable types
            return rawDict.compactMapValues { value -> any Sendable in
                value as! any Sendable
            }
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoSuchFileError {
                return nil
            }
            throw error
        }
    }

    func string(forKey key: String, at url: URL) throws -> String? {
        guard let dict = try dictionary(at: url) else {
            return nil
        }
        return dict[key] as? String
    }
}
