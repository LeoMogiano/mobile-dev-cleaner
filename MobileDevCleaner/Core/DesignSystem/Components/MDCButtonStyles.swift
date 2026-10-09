import SwiftUI

struct MDCPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.mdcMaterial) var material

    var height: CGFloat = 28
    var minWidth: CGFloat = 88
    var horizontalPadding: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .frame(height: height)
            .frame(minWidth: minWidth)
            .padding(.horizontal, horizontalPadding)
            .background {
                if material.usesGlass {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(nsColor: NSColor(
                                srgbRed: 0x3d / 255, green: 0x9b / 255, blue: 0xff / 255, alpha: 1
                            )),
                            .mdcAccent
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.mdcAccent
                }
            }
            .clipShape(RoundedRectangle(
                cornerRadius: material.usesGlass ? 999 : 6,
                style: .continuous
            ))
            .opacity(configuration.isPressed ? 0.85 : (isEnabled ? 1 : 0.4))
    }
}

struct MDCSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    var height: CGFloat = 26
    var horizontalPadding: CGFloat = 12
    var fontSize: CGFloat = 12
    var weight: Font.Weight = .medium

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: weight))
            .foregroundColor(.mdcText1)
            .frame(height: height)
            .padding(.horizontal, horizontalPadding)
            .mdcControl()
            .opacity(isEnabled ? 1 : 0.4)
    }
}

#Preview {
    VStack(spacing: 16) {
        Button("Primary Button") {}
            .buttonStyle(MDCPrimaryButtonStyle())

        Button("Secondary Button") {}
            .buttonStyle(MDCSecondaryButtonStyle())

        Button("Disabled") {}
            .buttonStyle(MDCPrimaryButtonStyle())
            .disabled(true)
    }
    .padding()
}
