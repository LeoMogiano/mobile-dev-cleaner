import SwiftUI

struct HowItWorksStep: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Cómo funciona")
                .font(.mont(28, weight: .bold))
                .tracking(-0.84)

            Text("Todo lo que encontramos cae en una de estas tres cajas.")
                .font(.system(size: 13.5))
                .foregroundStyle(Color.mdcText2)
                .padding(.top, 8)

            HStack(spacing: 12) {
                card(
                    backgroundColor: Color.mdcRegenBg,
                    iconColor: Color.mdcRegenInk,
                    icon: "arrow.triangle.2.circlepath",
                    title: "Se regenera solo",
                    description: "Casi todo se regenera solo cuando compilas."
                )

                card(
                    backgroundColor: Color.mdcCostBg,
                    iconColor: Color.mdcCostInk,
                    icon: "clock.arrow.circlepath",
                    title: "Tiene costo",
                    description: "Lo que tiene costo, te lo explicamos antes."
                )

                card(
                    backgroundColor: Color.mdcProtectedBg,
                    iconColor: Color.mdcText2,
                    icon: "lock.fill",
                    title: "Nunca lo tocamos",
                    description: "Lo delicado ni siquiera lo escaneamos."
                )
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 26)
        }
    }

    private func card(
        backgroundColor: Color,
        iconColor: Color,
        icon: String,
        title: LocalizedStringKey,
        description: LocalizedStringKey
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .center) {
                backgroundColor
                    .frame(width: 36, height: 36)
                    .cornerRadius(10)

                Image(systemName: icon)
                    .accessibilityHidden(true)
                    .font(.system(size: 19))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.top, 12)

            Text(description)
                .font(.system(size: 12.5))
                .foregroundStyle(Color.mdcText2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .mdcCard(radius: 12)
    }
}

#Preview {
    HowItWorksStep()
}
