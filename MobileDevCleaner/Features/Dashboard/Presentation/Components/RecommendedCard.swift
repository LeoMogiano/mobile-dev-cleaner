import SwiftUI

struct RecommendedCard: View {
    let sizeText: String
    let rows: [DashboardViewModel.CategoryRow]
    let isExpanded: Bool
    let hasMore: Bool
    let toggleLabel: String
    let onClean: () -> Void
    let onOpen: (CategoryID) -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            list.padding(.top, 14).padding(.leading, 52)
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 11))
                    .accessibilityHidden(true)
                Text("Esto volverá a crecer a medida que compiles. Es normal.")
            }
            .font(.system(size: 11.5))
            .foregroundStyle(Color.mdcText3)
            .padding(.top, 10).padding(.leading, 52)
        }
        .padding(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))
        .mdcCard()
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 19))
                .foregroundStyle(Color.mdcRegenInk)
                .frame(width: 38, height: 38)
                .background(Color.mdcRegenBg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Limpieza recomendada").font(.system(size: 15, weight: .semibold))
                (Text(sizeText).fontWeight(.semibold).foregroundStyle(Color.mdcText1)
                    + Text(" que Xcode y Gradle regeneran solos cuando los necesites."))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.mdcText2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Limpiar \(sizeText)", action: onClean)
                .buttonStyle(MDCPrimaryButtonStyle(height: 32, minWidth: 0))
        }
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                Button { onOpen(row.id) } label: {
                    HStack(spacing: 9) {
                        Image(systemName: row.symbol).font(.system(size: 13)).foregroundStyle(Color.mdcText2)
                            .accessibilityHidden(true)
                        Text(row.name).font(.system(size: 12.5)).frame(maxWidth: .infinity, alignment: .leading)
                        Text(row.sizeText).font(.system(size: 12)).monospacedDigit().foregroundStyle(Color.mdcText2)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) { Rectangle().fill(Color.mdcLine).frame(height: 0.5) }
            }
            if hasMore {
                Button(action: onToggle) {
                    HStack(spacing: 5) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right").font(.system(size: 11))
                            .accessibilityHidden(true)
                        Text(toggleLabel)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mdcAccentInk)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .mdcInner()
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
