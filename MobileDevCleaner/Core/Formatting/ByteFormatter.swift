import Foundation

enum ByteFormatter {
    private static let formatterCache = NumberFormatterCache()
    private static let decimalBase: Int64 = 1_000_000_000

    static func string(_ bytes: Int64, locale: Locale = .current) -> String {
        let (value, unit) = parts(bytes, locale: locale)
        return "\(value) \(unit)"
    }

    /// Returns formatted number and unit separately (for hero display with different font sizes).
    static func parts(_ bytes: Int64, locale: Locale = .current) -> (value: String, unit: String) {
        let megaBase: Int64 = 1_000_000

        if bytes >= decimalBase {
            let gb = Double(bytes) / Double(decimalBase)
            return (formatterCache.format(gb, locale: locale), "GB")
        } else {
            let mb = max(0, Int(round(Double(bytes) / Double(megaBase))))
            return (String(mb), "MB")
        }
    }
}

/// NumberFormatter is not Sendable; every access goes through the lock.
private final class NumberFormatterCache: @unchecked Sendable {
    private var cache: [String: NumberFormatter] = [:]
    private let lock = NSLock()

    func format(_ value: Double, locale: Locale) -> String {
        lock.lock()
        defer { lock.unlock() }
        let formatter = cache[locale.identifier] ?? makeFormatter(locale)
        cache[locale.identifier] = formatter
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    private func makeFormatter(_ locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = false
        return formatter
    }
}
