import SwiftUI

struct DeviceCard: View, Equatable {
    let card: DeviceCardModel
    let onSelectAction: (DeviceAction) -> Void
    let onInspect: () -> Void

    static func == (lhs: DeviceCard, rhs: DeviceCard) -> Bool {
        lhs.card == rhs.card
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            VStack(alignment: .leading, spacing: 7) {
                MDCBreakdownBar(segments: [
                    .init(id: "data", value: card.sizes.data, color: .mdcAccent),
                    .init(id: "cache", value: card.sizes.cache, color: .mdcCost),
                    .init(id: "snapshots", value: card.sizes.snapshots, color: .mdcSnapshots),
                    // Bars are relative to the whole device, so the system base stays empty.
                    .init(id: "other", value: card.sizes.other, color: .clear),
                ], height: 7, gap: 2)
                legend
            }
            DeviceActionPicker(segments: card.segments, isDisabled: card.isRunning, onSelect: onSelectAction)
            Text(card.actionDescription)
                .font(.system(size: 11.5))
                .foregroundStyle(descriptionColor)
                .frame(minHeight: 16, alignment: .leading)
        }
        .padding(16)
        .mdcCard(radius: 12)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(ringColor, lineWidth: card.chosen != nil ? 1.5 : 1)
        }
        .animation(.easeOut(duration: 0.2), value: card.chosen)
        .animation(.easeOut(duration: 0.2), value: card.isInspected)
        .contentShape(Rectangle())
        .onTapGesture(perform: onInspect)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(card.accessibilityLabel)
    }

    private var header: some View {
        HStack(spacing: 11) {
            Image(systemName: card.symbol)
                .font(.system(size: 20))
                .foregroundStyle(Color.mdcText1)
                .frame(width: 38, height: 38)
                .background(Color.mdcFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 0) {
                Text(card.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(card.osVersion)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.mdcText2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if card.isRunning {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.mdcAccent)
                        .frame(width: 6, height: 6)
                    Text("En uso")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.mdcAccentInk)
                .padding(.horizontal, 8)
                .frame(height: 20)
                .background(Color.mdcAccentBg, in: Capsule())
                .fixedSize()
            }
            Text(card.sizeText)
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .fixedSize()
        }
    }

    private var legend: some View {
        WrapLayout(horizontalSpacing: 14, verticalSpacing: 4) {
            ForEach(card.legend) { item in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(color(for: item.kind))
                        .frame(width: 8, height: 8)
                    Text(item.label)
                    Text(item.sizeText)
                        .foregroundStyle(Color.mdcText3)
                        .monospacedDigit()
                }
                .fixedSize()
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(Color.mdcText2)
    }

    private var ringColor: Color {
        if card.chosen != nil { return .mdcAccent }
        return card.isInspected ? .mdcLine2 : .clear
    }

    private var descriptionColor: Color {
        switch card.chosen {
        case .delete: .mdcDestructive
        case nil: .mdcText3
        default: .mdcText2
        }
    }

    private func color(for kind: DeviceLegendItem.Kind) -> Color {
        switch kind {
        case .data: .mdcAccent
        case .cache: .mdcCost
        case .snapshots: .mdcSnapshots
        }
    }
}

/// Left-aligned flow layout (CSS `flex-wrap`).
private struct WrapLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let frames = arrange(subviews, width: proposal.width ?? .infinity)
        let width = frames.map(\.maxX).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, frame) in zip(subviews, arrange(subviews, width: bounds.width)) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [CGRect] {
        var frames: [CGRect] = []
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += lineHeight + verticalSpacing
                lineHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }
        return frames
    }
}
