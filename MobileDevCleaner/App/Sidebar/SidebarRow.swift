import SwiftUI

/// 28 pt sidebar row: accent icon, name, optional trailing size or badge.
struct SidebarRow: View {
    /// Trailing chevron slot; `.reserved` keeps sizes aligned with the rows that have one.
    enum Disclosure: Equatable {
        case none, reserved
        case chevron(isOpen: Bool)
    }

    let title: String
    let symbol: String
    var trailing: String = ""
    var isSelected = false
    var isDimmed = false
    var iconColor: Color = .mdcAccent
    var disclosure: Disclosure = .none

    var body: some View {
        HStack(spacing: 8) {
            MDCSymbol(name: symbol, size: 15)
                .foregroundStyle(isSelected ? Color.white : iconColor)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            if !trailing.isEmpty {
                Text(trailing)
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.mdcText3)
                    .lineLimit(1)
            }
            disclosureView
        }
        .frame(height: 28)
        .opacity(isDimmed ? 0.45 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var disclosureView: some View {
        switch disclosure {
        case .none:
            EmptyView()
        case .reserved:
            Color.clear.frame(width: 10)
        case .chevron(let isOpen):
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.mdcText3)
                .rotationEffect(.degrees(isOpen ? 90 : 0))
                .frame(width: 10)
                .accessibilityHidden(true)
        }
    }
}
