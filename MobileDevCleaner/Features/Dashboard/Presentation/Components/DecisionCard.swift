import SwiftUI

struct DecisionCard: View {
    let rows: [DashboardViewModel.CategoryRow]
    let onOpen: (CategoryID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mdcCostInk)
                    .frame(width: 30, height: 30)
                    .background(Color.mdcCostBg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 0) {
                    Text("Requiere tu decisión").font(.system(size: 14, weight: .semibold))
                    Text("Tiene costo. Revísalo uno por uno.").font(.system(size: 12)).foregroundStyle(Color.mdcText2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    Button { onOpen(row.id) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: row.symbol)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.mdcText2)
                                .frame(width: 26)
                            Text(row.name)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.sizeText).font(.system(size: 12)).monospacedDigit().foregroundStyle(Color.mdcText2)
                            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Color.mdcText3)
                        }
                        .padding(.leading, 4).padding(.trailing, 6)
                        .frame(height: 36)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) { Rectangle().fill(Color.mdcLine).frame(height: 0.5) }
                }
            }
            .padding(.top, 8)
        }
        .padding(EdgeInsets(top: 16, leading: 18, bottom: 8, trailing: 18))
        .mdcCard()
    }
}
