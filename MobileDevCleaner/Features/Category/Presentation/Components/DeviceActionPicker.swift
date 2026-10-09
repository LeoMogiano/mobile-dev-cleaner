import SwiftUI

struct DeviceActionPicker: View {
    let segments: [DeviceSegmentModel]
    let isDisabled: Bool
    let onSelect: (DeviceAction) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(segments) { segment in
                Button { onSelect(segment.id) } label: {
                    Text(segment.label)
                        .font(.system(size: 12, weight: segment.isOn ? .semibold : .regular))
                        .foregroundStyle(segment.isOn ? ink(segment.risk) : Color.mdcText1)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                        .background {
                            if segment.isOn {
                                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.mdcSegmentOn)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(segment.freesText)
                .accessibilityLabel("\(segment.label), \(segment.freesText)")
                .accessibilityAddTraits(segment.isOn ? .isSelected : [])
            }
        }
        .padding(2)
        .background(Color.mdcSegment, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .opacity(isDisabled ? 0.5 : 1)
        // Not `.disabled`: the tap must still reach the view model, which explains why.
        .help(isDisabled ? L10n.string("Ciérralo para poder limpiarlo") : "")
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Acción")
    }

    private func ink(_ risk: RiskLevel) -> Color {
        risk == .regenerates ? .mdcRegenInk : .mdcCostInk
    }
}
