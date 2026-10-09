import SwiftUI

struct MDCEmptyState: View {
    let symbol: String
    var tint: Color = .mdcRegen
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(tint.opacity(0.15))
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(tint)
                }

            Text(title)
                .font(.mont(28, weight: .bold))
                .tracking(-0.84)
                .foregroundColor(.mdcText1)
                .padding(.top, 22)

            Text(message)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.mdcText2)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
                .padding(.top, 8)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                        Text(actionTitle)
                    }
                }
                .buttonStyle(MDCSecondaryButtonStyle())
                .padding(.top, 22)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(EdgeInsets(top: 70, leading: 20, bottom: 40, trailing: 20))
    }
}

#Preview {
    VStack {
        MDCEmptyState(
            symbol: "checkmark.circle.fill",
            tint: .mdcRegen,
            title: "Tu Mac está ordenada.",
            message: "No hay nada que limpiar ahora mismo. Vuelve después de unas semanas de builds.",
            actionTitle: "Escanear de nuevo",
            action: {}
        )
    }
}
