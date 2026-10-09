import SwiftUI

struct DoneStep: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .center) {
                Circle()
                    .fill(Color.mdcRegenBg)
                    .frame(width: 84, height: 84)

                Image(systemName: "checkmark.shield.fill")
                    .accessibilityHidden(true)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.mdcRegenInk)
            }

            Text("Todo listo.")
                .font(.mont(32, weight: .bold))
                .tracking(-1.12)
                .padding(.top, 24)

            Text("Todo ocurre en tu Mac. Sin telemetría, sin internet. Nada se borra sin que lo revises antes.")
                .font(.system(size: 14))
                .foregroundStyle(Color.mdcText2)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 440)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DoneStep()
}
