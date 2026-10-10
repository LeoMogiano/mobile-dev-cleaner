import SwiftUI

struct ResultFailureList: View {
    let header: String
    let failures: [ResultFailureRow]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onShowInFinder: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mdcCostInk)
                        .accessibilityHidden(true)
                    Text(header)
                        .font(.system(size: 12.5, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.mdcText3)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 12)
                .frame(height: 34)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? L10n.string("Expandido") : L10n.string("Contraído"))

            if isExpanded {
                ForEach(failures) { row in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(row.name)
                                .font(.system(size: 12.5, weight: .medium))
                            Text(row.reason)
                                .font(.system(size: 11.5))
                                .foregroundStyle(Color.mdcText2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Button { onShowInFinder(row.id) } label: {
                            Label("Mostrar en Finder", systemImage: "arrow.up.forward.circle")
                                .labelStyle(SpacedLabelStyle(spacing: 4))
                        }
                        .buttonStyle(MDCSecondaryButtonStyle(height: 24, horizontalPadding: 9, fontSize: 11.5, weight: .regular))
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 12)
                    .overlay(alignment: .top) { Rectangle().fill(Color.mdcLine).frame(height: 0.5) }
                }
            }
        }
        .mdcInner(radius: 10)
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.mdcLine, lineWidth: 0.5))
    }
}

struct SpacedLabelStyle: LabelStyle {
    let spacing: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            configuration.icon
            configuration.title
        }
    }
}
