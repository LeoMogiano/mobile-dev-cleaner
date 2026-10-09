import SwiftUI

struct HistoryRow: View {
    let row: HistoryRowModel
    let onToggle: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: row.iconName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.mdcText3)
                        .accessibilityHidden(true)

                    Text(row.dateText)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 130, alignment: .leading)

                    Text(row.countText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.mdcText2)

                    Spacer()

                    Text(row.freedText)
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                }
                .frame(height: 42)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .background(isHovered ? Color.mdcHover : .clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
            .accessibilityElement(children: .combine)
            .accessibilityValue(row.isExpanded ? L10n.string("Expandido") : L10n.string("Contraído"))

            if row.isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(row.breakdown) { slice in
                        HStack(alignment: .center, spacing: 10) {
                            Text(slice.name)
                                .font(.system(size: 12, weight: .regular))
                                .frame(width: 180, alignment: .leading)
                                .lineLimit(1)
                                .accessibilityHidden(true)

                            GeometryReader { proxy in
                                Capsule()
                                    .fill(Color.mdcAccent)
                                    .frame(width: proxy.size.width * slice.fraction)
                            }
                            .frame(height: 4)
                            .background(Color.mdcFill, in: Capsule())
                            .accessibilityElement()
                            .accessibilityLabel("\(slice.name), \(slice.valueText)")
                            .accessibilityValue("\(Int((slice.fraction * 100).rounded()))%")

                            Text(slice.valueText)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.mdcText2)
                                .monospacedDigit()
                                .frame(width: 60, alignment: .trailing)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .padding(EdgeInsets(top: 2, leading: 38, bottom: 14, trailing: 16))
            }
        }
    }
}
