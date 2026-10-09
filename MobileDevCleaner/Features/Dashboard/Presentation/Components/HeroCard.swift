import SwiftUI

struct HeroCard: View {
    let bytes: Int64
    let regenBytes: Int64
    let costBytes: Int64
    let regenText: String
    let costText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Puedes recuperar")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.mdcText2)
            MDCHeroNumber(bytes: bytes)
                .foregroundStyle(Color.mdcText1)
                .padding(.top, 4)
            MDCBreakdownBar(
                segments: [
                    .init(id: "regen", value: regenBytes, color: .mdcRegen),
                    .init(id: "cost", value: costBytes, color: .mdcCost)
                ],
                height: 12,
                gap: 2
            )
            .padding(.top, 18)
            HStack(spacing: 20) {
                legend("Se regenera solo", value: regenText, color: .mdcRegen)
                legend("Tiene costo", value: costText, color: .mdcCost)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 22, leading: 24, bottom: 20, trailing: 24))
        .mdcCard(radius: 16)
    }

    private func legend(_ title: LocalizedStringKey, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous).fill(color).frame(width: 9, height: 9)
            Text(title)
            Text(value).fontWeight(.semibold).monospacedDigit().foregroundStyle(Color.mdcText1)
        }
        .font(.system(size: 12))
        .foregroundStyle(Color.mdcText2)
    }
}
