import SwiftUI

struct DeviceActionPicker: View {
    let segments: [DeviceSegmentModel]
    let isDisabled: Bool
    let onSelect: (DeviceAction) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(segments) { segment in
                Button { onSelect(segment.id) } label: {
                    label(for: segment)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(segment.label), \(segment.freesText)")
                .accessibilityAddTraits(segment.isOn ? .isSelected : [])
            }
        }
        .padding(2)
        .background(Color.mdcSegment, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .opacity(isDisabled ? 0.5 : 1)
        // Not `.disabled`: the tap must still reach the view model, which explains why.
        .help(isDisabled ? "Ciérralo para poder limpiarlo" : "")
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Acción")
    }

    private func label(for segment: DeviceSegmentModel) -> some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        let tint: Color = segment.risk == .regenerates ? .mdcRegen : .mdcCost
        let ink: Color = segment.risk == .regenerates ? .mdcRegenInk : .mdcCostInk
        return VStack(spacing: 1) {
            HStack(spacing: 5) {
                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                Text(segment.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(segment.isOn ? ink : Color.mdcText1)
            }
            Text(segment.freesText)
                .font(.system(size: 10.5))
                .monospacedDigit()
                .foregroundStyle(Color.mdcText2)
        }
        .lineLimit(1)
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .background {
            if segment.isOn {
                shape
                    .fill(Color.mdcSegmentOn)
                    .overlay(shape.strokeBorder(tint, lineWidth: 1.5))
            }
        }
        .contentShape(shape)
    }
}
