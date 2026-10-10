#if DEBUG
import SwiftUI

/// Cleanup sheets and history components with the prototype's sample data (`mkData`, `mkHistory`).
struct SheetsGallery: View {
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 24) {
                sheet {
                    ReviewContent(
                        totalText: "12,4 GB", countText: "9 elementos",
                        regenerateHeader: "7 elementos · 7,7 GB",
                        regenerateRows: [
                            ReviewGroupRow(id: .builds, name: "Builds de Xcode", symbol: "hammer", countText: "4 elementos", sizeText: "6,1 GB"),
                            ReviewGroupRow(id: .gcache, name: "Cachés de Gradle", symbol: "shippingbox", countText: "3 elementos", sizeText: "1,6 GB"),
                        ],
                        costHeader: "2 elementos · 4,7 GB",
                        costRows: [
                            ReviewCostRow(id: "gd1", name: "files-2.1", categoryName: "Dependencias de Gradle", sizeText: "4,6 GB",
                                          note: "files-2.1: gradle volverá a descargar ~4,6 GB en el próximo build."),
                            ReviewCostRow(id: "s2", name: "iPad Air · Restablecer", categoryName: "Simuladores iOS", sizeText: "1,2 GB",
                                          note: "iPad Air: quedará como recién creado. Se pierden sus apps y datos."),
                        ],
                        commands: ["mv \"~/Library/Developer/Xcode/DerivedData/MyBankApp-abcd\" ~/.Trash/", "/usr/bin/xcrun simctl erase A81D44E0-0B47"],
                        movesToTrash: true, needsUnderstanding: true, understands: false,
                        primaryTitle: "Entiendo, limpiar", canClean: false,
                        onToggleTrash: {}, onToggleUnderstands: {}, onCancel: {}, onClean: {})
                }
                sheet {
                    BlockedContent(
                        apps: [
                            BlockingAppRow(id: .xcode, name: "Xcode", detail: "Puede tener un build en curso", symbol: "hammer", tool: .xcode),
                            BlockingAppRow(id: .androidEmulator, name: "Emulador Android", detail: "Pixel_8_API_34", symbol: "smartphone", tool: .android),
                            BlockingAppRow(id: .flutterTool, name: "Flutter", detail: "Puede tener una compilación en curso", symbol: "flutter", tool: .flutter),
                        ],
                        isRechecking: false, onCancel: {}, onRecheck: {})
                }
            }
            VStack(spacing: 24) {
                sheet {
                    ProgressContent(
                        fraction: 0.62, freedText: "7,7 GB", ofTotalText: "de 12,4 GB",
                        stepText: "6 de 9 · transforms-4", onCancel: {})
                }
                sheet {
                    ResultContent(
                        freedText: "12,4 GB", countText: "9 elementos", wasCancelled: false, showsTrashNote: true,
                        failureHeader: "1 no se pudo limpiar",
                        failures: [ResultFailureRow(id: "t1", name: "MyBankApp · 42 ejecuciones", reason: "Lo está usando otro proceso.")],
                        isFailuresExpanded: true,
                        onToggleFailures: {}, onShowInFinder: { _ in }, onShowHistory: {}, onDone: {})
                }
                VStack(spacing: 16) {
                    HistorySummaryCard(totalText: "38,6 GB", countText: "2 limpiezas", bars: [
                        HistoryBar(id: UUID(), label: "27 ago", valueText: "17,6 GB", fraction: 17.6 / 21),
                        HistoryBar(id: UUID(), label: "12 sep", valueText: "21 GB", fraction: 1),
                    ])
                    HistoryRow(row: HistoryRowModel(
                        id: UUID(), dateText: "12 sep 2026", countText: "14 elementos", freedText: "21 GB", isExpanded: true,
                        breakdown: [
                            HistorySliceModel(id: "builds", name: "Builds de Xcode", valueText: "8,2 GB", fraction: 8.2 / 21),
                            HistorySliceModel(id: "gcache", name: "Cachés de Gradle", valueText: "7,9 GB", fraction: 7.9 / 21),
                            HistorySliceModel(id: "other", name: "Otros", valueText: "4,9 GB", fraction: 4.9 / 21),
                        ]), onToggle: {})
                    .mdcCard(radius: 12)
                }
                .frame(width: 560)
            }
        }
        .font(.system(size: 13))
        .foregroundStyle(Color.mdcText1)
        .padding(24)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func sheet<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(width: 520)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    }
}
#endif
