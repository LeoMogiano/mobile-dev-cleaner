import SwiftUI

struct ProgressContent: View {
    /// 0...1
    let fraction: Double
    let freedText: String
    let ofTotalText: String
    /// "3 de 10 · DerivedData de MyApp".
    let stepText: String
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .center, spacing: 0) {
                ZStack(alignment: .center) {
                    Circle()
                        .stroke(Color.mdcFill, lineWidth: 7)

                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(Color.mdcAccent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(
                            reduceMotion ? nil : .easeOut(duration: 0.25),
                            value: fraction
                        )

                    Text("\(Int((fraction * 100).rounded()))%")
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .monospacedDigit()
                }
                .frame(width: 104, height: 104)
                .accessibilityElement()
                .accessibilityLabel("Limpiando")
                .accessibilityValue("\(Int((fraction * 100).rounded()))%")

                Text("Limpiando…")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.top, 16)

                HStack(spacing: 0) {
                    Text(freedText)
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .monospacedDigit()
                        .tracking(-0.48)
                    + Text(" ")
                    + Text(ofTotalText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.mdcText2)
                }
                .padding(.top, 4)

                Text(stepText)
                    .font(.system(size: 12))
                    .foregroundColor(.mdcText3)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 420)
                    .padding(.top, 8)
            }
            .padding(EdgeInsets(top: 28, leading: 26, bottom: 8, trailing: 26))

            HStack(spacing: 8) {
                Text("Si cancelas, lo que ya se limpió queda limpio.")
                    .font(.system(size: 11.5))
                    .foregroundColor(.mdcText3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Cancelar", action: onCancel)
                .buttonStyle(MDCSecondaryButtonStyle(height: 28, horizontalPadding: 14, fontSize: 13, weight: .regular))
                .keyboardShortcut(.cancelAction)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
        }
    }
}
