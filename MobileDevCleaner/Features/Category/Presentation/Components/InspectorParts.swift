import SwiftUI

struct InspectorHeader: View {
    let name: String
    let badge: MDCBadgeKind
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                MDCRiskBadge(kind: badge)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .help("Cerrar")
            .accessibilityLabel("Cerrar")
        }
        .foregroundColor(.mdcText1)
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .overlay(alignment: .bottom) { Divider().foregroundColor(.mdcLine) }
    }
}

struct InspectorField: View {
    let label: LocalizedStringKey
    let value: String
    var isMono = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.mdcText3)
            Text(value)
                .font(.system(size: 12.5, weight: .regular, design: isMono ? .monospaced : .default))
                .foregroundColor(.mdcText1)
                .lineLimit(nil)
        }
        .accessibilityElement(children: .combine)
    }
}

struct InspectorFooter: View {
    let markLabel: String?
    let onShowInFinder: () -> Void
    let onMark: (() -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onShowInFinder) {
                HStack(spacing: 5) {
                    Image(systemName: "finder")
                        .accessibilityHidden(true)
                        .font(.system(size: 12, weight: .regular))
                    Text("Mostrar en Finder")
                }
            }
            .buttonStyle(MDCSecondaryButtonStyle())

            if let markLabel, let onMark {
                Button(markLabel, action: onMark)
                    .buttonStyle(MDCSecondaryButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .overlay(alignment: .top) { Divider().foregroundColor(.mdcLine) }
    }
}

/// RelativeDateTimeFormatter is not thread-safe; only the inspector (main actor) uses it.
@MainActor
enum InspectorDateFormat {
    private static let formatter: RelativeDateTimeFormatter = {
        let fmt = RelativeDateTimeFormatter()
        fmt.locale = AppLanguage.current.locale
        fmt.unitsStyle = .abbreviated
        return fmt
    }()

    static func string(for date: Date) -> String {
        formatter.localizedString(for: date, relativeTo: .now)
    }
}
