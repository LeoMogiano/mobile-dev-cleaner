import SwiftUI

struct DeviceCard: View, Equatable {
    let card: DeviceCardModel
    let onSelectAction: (DeviceAction) -> Void
    let onInspect: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static func == (lhs: DeviceCard, rhs: DeviceCard) -> Bool {
        lhs.card == rhs.card
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            DeviceActionPicker(segments: card.segments, isDisabled: card.isRunning, onSelect: onSelectAction)
            if let description = card.actionDescription {
                Text(description)
                    .font(.system(size: 11.5))
                    .foregroundStyle(card.chosen == .delete ? Color.mdcDestructiveInk : Color.mdcText2)
                    .lineLimit(1)
                    .transition(.opacity)
            }
        }
        .padding(14)
        .mdcCard(radius: 12)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(ringColor, lineWidth: 1)
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: card.chosen)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: card.isInspected)
        .contextMenu {
            Button("Ver detalles", action: onInspect)
        }
        .accessibilityAction(named: "Ver detalles", onInspect)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(card.accessibilityLabel)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: card.symbol)
                .font(.system(size: 18))
                .foregroundStyle(Color.mdcText2)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(card.name)
                    .font(.system(size: 13.5, weight: .semibold))
                Text(card.osVersion)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.mdcText3)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            if card.isRunning {
                Text("En uso")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.mdcAccentInk)
                    .fixedSize()
            }
            Text(card.sizeText)
                .font(.system(size: 13.5, weight: .semibold))
                .monospacedDigit()
                .fixedSize()
        }
    }

    private var ringColor: Color {
        if card.chosen != nil { return .mdcAccent }
        return card.isInspected ? .mdcLine2 : .clear
    }
}
