import SwiftUI

struct HistorySummaryCard: View {
    let totalText: String
    let countText: String
    let bars: [HistoryBar]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom, spacing: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Espacio liberado en total")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.mdcText2)

                    Text(totalText)
                        .font(.mont(40, weight: .bold))
                        .tracking(-1.6)
                        .lineLimit(1)
                        .padding(.top, 2)

                    Text(countText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.mdcText3)
                        .padding(.top, 4)
                }

                Spacer()

                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(bars) { bar in
                        VStack(alignment: .center, spacing: 5) {
                            Text(bar.valueText)
                                .font(.system(size: 10.5, weight: .regular))
                                .foregroundColor(.mdcText2)
                                .lineLimit(1)

                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.mdcRegen)
                                .frame(width: 26, height: max(4, bar.fraction * 70))

                            Text(bar.label)
                                .font(.system(size: 10.5, weight: .regular))
                                .foregroundColor(.mdcText3)
                                .lineLimit(1)
                        }
                        .frame(width: 44)
                    }
                }
                .frame(height: 110)
            }

            Rectangle()
                .fill(Color.mdcLine)
                .frame(height: 0.5)
                .padding(.top, 16)
                .padding(.bottom, 12)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.mdcRegenInk)
                    .padding(.top, 1)

                Text("El espacio vuelve a crecer mientras desarrollas. Por eso conviene limpiar cada 2–4 semanas.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.mdcText2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(EdgeInsets(top: 20, leading: 22, bottom: 20, trailing: 22))
        .mdcCard(radius: 14)
    }
}
