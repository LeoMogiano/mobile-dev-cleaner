import SwiftUI

struct MDCSwitchToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label

            Button(action: { configuration.isOn.toggle() }) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(configuration.isOn ? Color.mdcRegen : Color.mdcLine2)
                        .frame(width: 36, height: 20)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: configuration.isOn ? 18 : 2, y: 0)
                        .shadow(color: Color.black.opacity(0.15), radius: 0.5, x: 0, y: 0.5)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 36, height: 20)
            .animation(
                !reduceMotion ? .spring(response: 0.2, dampingFraction: 1, blendDuration: 0) : .none,
                value: configuration.isOn
            )
            .accessibilityElement()
            .accessibilityValue(configuration.isOn ? L10n.string("Activado") : L10n.string("Desactivado"))
            .accessibilityAddTraits(.isToggle)
        }
    }
}

#Preview {
    @Previewable @State var isOn = false
    @Previewable @State var isOn2 = true

    VStack(spacing: 20) {
        Toggle("Opción 1", isOn: $isOn)
        Toggle("Opción 2", isOn: $isOn2)
    }
    .toggleStyle(MDCSwitchToggleStyle())
    .padding()
}
