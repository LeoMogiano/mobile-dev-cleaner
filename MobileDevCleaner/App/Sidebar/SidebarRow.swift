import SwiftUI

/// 28 pt sidebar row: accent icon, name, optional trailing size or badge.
struct SidebarRow: View {
    let title: String
    let symbol: String
    var trailing: String = ""
    var isSelected = false
    var isDimmed = false
    var iconColor: Color = .mdcAccent
    var badge: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 15))
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
            if let badge {
                Text(badge)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.mdcText2)
                    .padding(.horizontal, 6)
                    .frame(height: 16)
                    .background(Color.mdcFill, in: Capsule())
            }
        }
        .frame(height: 28)
        .opacity(isDimmed ? 0.45 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Section header: title plus total on the right.
struct SidebarSectionHeader: View {
    let title: String
    var total = ""

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(size: 11, weight: .bold))
            Spacer(minLength: 0)
            if !total.isEmpty {
                Text(total).font(.system(size: 11, weight: .semibold)).monospacedDigit()
            }
        }
        .foregroundStyle(Color.mdcText3)
        .textCase(nil)
        // Rows sit inside the selection inset; this lines the total up with row sizes.
        .padding(.trailing, 14)
        .accessibilityElement(children: .combine)
    }
}
