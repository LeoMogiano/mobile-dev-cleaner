import SwiftUI

struct DoneStep: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .center) {
                Circle()
                    .fill(Color.mdcRegenBg)
                    .frame(width: 84, height: 84)

                Image(systemName: "checkmark.shield.fill")
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
                .lineLimit(3)
                .padding(.top, 10)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DoneStep()
}
