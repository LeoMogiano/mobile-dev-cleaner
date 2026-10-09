import SwiftUI

struct MDCCheckbox: View {
    let isOn: Bool
    var isEnabled = true
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isOn ? Color.mdcAccent : (colorScheme == .dark ? Color.mdcText3 : Color.white))
                    .frame(width: 14, height: 14)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.mdcLine2, lineWidth: 0.5)
                    .frame(width: 14, height: 14)

                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement()
        .accessibilityLabel(isOn ? "Marcado" : "Desmarcado")
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "on" : "off")
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            MDCCheckbox(isOn: false, isEnabled: true, action: {})
            Text("Off")
        }
        HStack {
            MDCCheckbox(isOn: true, isEnabled: true, action: {})
            Text("On")
        }
        HStack {
            MDCCheckbox(isOn: false, isEnabled: false, action: {})
            Text("Disabled")
        }
    }
    .preferredColorScheme(.light)
    .frame(width: 200)
    .padding()

    VStack(spacing: 20) {
        HStack {
            MDCCheckbox(isOn: false, isEnabled: true, action: {})
            Text("Off")
        }
        HStack {
            MDCCheckbox(isOn: true, isEnabled: true, action: {})
            Text("On")
        }
        HStack {
            MDCCheckbox(isOn: false, isEnabled: false, action: {})
            Text("Disabled")
        }
    }
    .preferredColorScheme(.dark)
    .frame(width: 200)
    .padding()
}
