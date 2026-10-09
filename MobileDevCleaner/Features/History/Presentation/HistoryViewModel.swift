import SwiftUI
import Foundation

struct HistoryBar: Identifiable, Hashable {
    let id: UUID
    let label: String
    let valueText: String
    let fraction: Double
}

struct HistorySliceModel: Identifiable, Hashable {
    let id: String
    let name: String
    let valueText: String
    let fraction: Double
}

struct HistoryRowModel: Identifiable, Hashable {
    let id: UUID
    let dateText: String
    let countText: String
    let freedText: String
    let isExpanded: Bool
    let breakdown: [HistorySliceModel]

    var iconName: String { isExpanded ? "chevron.down" : "chevron.right" }
}

@MainActor @Observable
final class HistoryViewModel {
    private let store: HistoryStore
    var expandedID: UUID?

    private static let dateFormatterCache = DateFormatterCache()

    init(store: HistoryStore) {
        self.store = store
    }

    var isEmpty: Bool { store.entries.isEmpty }

    var totalText: String {
        ByteFormatter.string(store.totalFreed, locale: AppLanguage.current.locale)
    }

    var countText: String {
        let count = store.entries.count
        return count == 1 ? "1 limpieza" : "\(count) limpiezas"
    }

    var bars: [HistoryBar] {
        let locale = AppLanguage.current.locale
        let dateFormatter = Self.dateFormatterCache.dateFormatter(locale: locale)
        let maxBytes = store.entries.max(by: { $0.freedBytes < $1.freedBytes })?.freedBytes ?? 1
        return store.entries.suffix(6).reversed().map { entry in
            let label = dateFormatter.string(from: entry.date)
            let valueText = ByteFormatter.string(entry.freedBytes, locale: locale)
            let fraction = maxBytes > 0 ? Double(entry.freedBytes) / Double(maxBytes) : 0
            return HistoryBar(
                id: entry.id,
                label: label,
                valueText: valueText,
                fraction: fraction
            )
        }
    }

    var rows: [HistoryRowModel] {
        let locale = AppLanguage.current.locale
        let dateFormatter = Self.dateFormatterCache.dateFormatter(locale: locale)
        let timeFormatter = Self.dateFormatterCache.timeFormatter(locale: locale)

        return store.entries.map { entry in
            let isToday = Calendar.current.isDateInToday(entry.date)
            let isYesterday = Calendar.current.isDateInYesterday(entry.date)
            let dateText = isToday ? "Hoy, \(timeFormatter.string(from: entry.date))" :
                           isYesterday ? "Ayer, \(timeFormatter.string(from: entry.date))" :
                           dateFormatter.string(from: entry.date)

            let countText = entry.itemCount == 1 ? "1 elemento" : "\(entry.itemCount) elementos"
            let freedText = ByteFormatter.string(entry.freedBytes, locale: AppLanguage.current.locale)
            let isExpanded = expandedID == entry.id

            let maxBytes = entry.breakdown.max(by: { $0.bytes < $1.bytes })?.bytes ?? 1
            let breakdown = entry.breakdown.prefix(3).map { slice in
                let categoryName = CategoryInfo.info(for: slice.category).name
                let fraction = maxBytes > 0 ? Double(slice.bytes) / Double(maxBytes) : 0
                return HistorySliceModel(
                    id: "\(entry.id)_\(slice.category.rawValue)",
                    name: categoryName,
                    valueText: ByteFormatter.string(slice.bytes, locale: AppLanguage.current.locale),
                    fraction: fraction
                )
            }

            let fullBreakdown: [HistorySliceModel]
            if entry.breakdown.count > 3 {
                let shown = entry.breakdown.prefix(3)
                let others = entry.breakdown.dropFirst(3).reduce(0) { $0 + $1.bytes }
                let othersFraction = maxBytes > 0 ? Double(others) / Double(maxBytes) : 0
                fullBreakdown = Array(breakdown) + [
                    HistorySliceModel(
                        id: "\(entry.id)_others",
                        name: "Otros",
                        valueText: ByteFormatter.string(others, locale: AppLanguage.current.locale),
                        fraction: othersFraction
                    )
                ]
            } else {
                fullBreakdown = Array(breakdown)
            }

            return HistoryRowModel(
                id: entry.id,
                dateText: dateText,
                countText: countText,
                freedText: freedText,
                isExpanded: isExpanded,
                breakdown: fullBreakdown
            )
        }
    }

    func handle(_ intent: HistoryViewIntent) {
        switch intent {
        case .toggle(let id):
            expandedID = expandedID == id ? nil : id
        }
    }
}

enum HistoryViewIntent: Sendable {
    case toggle(UUID)
}

private final class DateFormatterCache {
    private var dateFormatters: [String: DateFormatter] = [:]
    private var timeFormatters: [String: DateFormatter] = [:]

    func dateFormatter(locale: Locale) -> DateFormatter {
        let id = locale.identifier
        if let cached = dateFormatters[id] { return cached }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = locale
        dateFormatters[id] = formatter
        return formatter
    }

    func timeFormatter(locale: Locale) -> DateFormatter {
        let id = locale.identifier
        if let cached = timeFormatters[id] { return cached }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = locale
        timeFormatters[id] = formatter
        return formatter
    }
}
