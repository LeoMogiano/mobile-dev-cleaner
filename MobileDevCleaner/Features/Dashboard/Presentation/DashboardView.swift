import SwiftUI

struct DashboardView: View {
    @Environment(ScanStore.self) private var scan
    @Environment(SelectionStore.self) private var selection
    @Environment(SettingsStore.self) private var settings
    @Environment(AppRouter.self) private var router
    @Environment(HistoryStore.self) private var history
    @State private var model: DashboardViewModel?

    var body: some View {
        ScrollView {
            if let model {
                content(model)
                    .frame(maxWidth: 820)
                    .frame(maxWidth: .infinity)
                    .padding(EdgeInsets(top: 22, leading: 24, bottom: 90, trailing: 24))
            }
        }
        .task {
            if model == nil {
                model = DashboardViewModel(
                    scan: scan, selection: selection, settings: settings, router: router, history: history)
            }
        }
    }

    @ViewBuilder
    private func content(_ model: DashboardViewModel) -> some View {
        VStack(spacing: 14) {
            if model.showsAccessBanner {
                MDCBanner(
                    message: "Algunas carpetas no se pudieron medir.",
                    actionTitle: "Dar acceso",
                    onAction: { model.handle(.grantAccess) },
                    onDismiss: { model.handle(.dismissBanner) }
                )
            }
            switch model.state {
            case .scanning:
                ScanningCard(
                    percentText: model.percentText, currentPath: model.currentPath,
                    progress: model.toolProgress, rows: model.scanRows
                )
            case .clean:
                clean(model)
            case .results:
                results(model)
            }
        }
    }

    private func clean(_ model: DashboardViewModel) -> some View {
        VStack(spacing: 0) {
            MDCEmptyState(
                symbol: "checkmark", title: "Tu Mac está ordenada.",
                message: "No hay nada que limpiar ahora mismo. Vuelve después de unas semanas de builds.",
                actionTitle: "Escanear de nuevo", action: { model.handle(.rescan) }
            )
            .frame(height: 440)
            footer(model)
        }
    }

    @ViewBuilder
    private func results(_ model: DashboardViewModel) -> some View {
        HeroCard(
            bytes: model.heroBytes, regenBytes: model.regenSize, costBytes: model.costSize,
            regenText: model.regenText, costText: model.costText
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(model.heroAccessibility)
        if model.hasRecommended {
            RecommendedCard(
                sizeText: model.recommendedText, rows: model.visibleRecommended,
                isExpanded: model.isRecommendedExpanded, hasMore: model.hasMoreRecommended,
                toggleLabel: model.recommendedToggleLabel,
                onClean: { model.handle(.cleanRecommended) },
                onOpen: { model.handle(.openCategory($0)) },
                onToggle: { model.handle(.toggleRecommendedList) }
            )
        }
        if !model.decisionRows.isEmpty {
            DecisionCard(rows: model.decisionRows, onOpen: { model.handle(.openCategory($0)) })
        }
        footer(model).padding(.vertical, 4)
    }

    private func footer(_ model: DashboardViewModel) -> some View {
        Text(model.footer())
            .font(.system(size: 11))
            .foregroundStyle(Color.mdcText3)
            .frame(maxWidth: .infinity)
    }
}
