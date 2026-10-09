import SwiftUI

struct ScanningCard: View {
    let percentText: String
    let currentPath: String
    let progress: [DashboardViewModel.ToolProgress]
    let rows: [DashboardViewModel.ScanRow]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 14) {
            summary
            rowsCard
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ProgressView().controlSize(.small)
                Text("Escaneando tu Mac…").font(.system(size: 17, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
                Text(percentText).font(.system(size: 13)).monospacedDigit().foregroundStyle(Color.mdcText2)
                    .accessibilityLabel("Progreso del escaneo")
            }
            Text(currentPath)
                .font(.mdcMono(11))
                .foregroundStyle(Color.mdcText3)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.top, 6)
            HStack(alignment: .top, spacing: 18) {
                ForEach(progress) { toolColumn($0) }
            }
            .padding(.top, 18)
        }
        .padding(EdgeInsets(top: 22, leading: 24, bottom: 22, trailing: 24))
        .mdcCard()
    }

    private func toolColumn(_ item: DashboardViewModel.ToolProgress) -> some View {
        let color = Color.mdcTool(item.tool)
        return VStack(spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: item.tool == .xcode ? "hammer" : "cpu").font(.system(size: 13)).foregroundStyle(color)
                Text(item.tool == .xcode ? "Xcode" : "Android").fontWeight(.semibold)
                Spacer(minLength: 0)
                Text(item.foundText).foregroundStyle(Color.mdcText2).monospacedDigit()
            }
            .font(.system(size: 12))
            GeometryReader { proxy in
                Capsule().fill(color).frame(width: proxy.size.width * item.fraction)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: item.fraction)
            }
            .frame(height: 5)
            .background(Color.mdcFill, in: Capsule())
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
    }

    private var rowsCard: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                scanRow(row)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .overlay(alignment: .bottom) { Rectangle().fill(Color.mdcLine).frame(height: 0.5) }
            }
        }
        .mdcCard(radius: 12)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func scanRow(_ row: DashboardViewModel.ScanRow) -> some View {
        HStack(spacing: 10) {
            if row.isFound {
                Image(systemName: row.symbol).font(.system(size: 14)).foregroundStyle(Color.mdcTool(row.tool))
                Text(row.name).frame(maxWidth: .infinity, alignment: .leading)
                Text(row.sizeText)
                    .font(.system(size: 12))
                    .monospacedDigit()
                    .foregroundStyle(row.isDimmed ? Color.mdcText3 : Color.mdcText1)
            } else {
                block(14, 14, radius: 4)
                block(160, 9, radius: 5)
                Spacer(minLength: 0)
                block(48, 9, radius: 5)
            }
        }
        .accessibilityElement(children: .combine)
        .transition(reduceMotion ? .identity : .opacity.animation(.easeOut(duration: 0.26)))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.26), value: row.isFound)
    }

    private func block(_ width: CGFloat, _ height: CGFloat, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Color.mdcFill).frame(width: width, height: height)
    }
}
