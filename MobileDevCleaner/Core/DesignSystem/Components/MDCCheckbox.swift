import SwiftUI

struct MDCCheckbox: View {
    let isOn: Bool
    var isEnabled = true
    let action: () -> Void

    private static let offFill = Color(light: (0xFFFFFF, 1), dark: (0xFFFFFF, 0.1))

    var body: some View {
        Button(action: action) {
            let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
            ZStack {
                shape.fill(isOn ? Color.mdcAccent : Self.offFill)
                if !isOn { shape.strokeBorder(Color.mdcLine2, lineWidth: 1) }
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(isOn ? 1 : 0)
            }
            .frame(width: 15, height: 15)
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
