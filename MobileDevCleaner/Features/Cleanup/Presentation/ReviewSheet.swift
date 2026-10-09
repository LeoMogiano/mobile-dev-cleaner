import SwiftUI

/// Hosts the whole cleanup flow: review → (blocked) → progress → result.
struct ReviewSheet: View {
    @Environment(ScanStore.self) private var scan
    @Environment(SelectionStore.self) private var selection
    @Environment(SettingsStore.self) private var settings
    @Environment(HistoryStore.self) private var history
    @Environment(AppRouter.self) private var router
    @State private var viewModel: CleanupFlowViewModel?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: viewModel.stage)
                    .interactiveDismissDisabled(viewModel.stage == .progress)
            } else {
                checking
            }
        }
        .frame(width: 520)
        .frame(maxHeight: 600)
        .onExitCommand { viewModel?.handle(.dismiss) }
        .task {
            guard viewModel == nil else { return }
            let model = CleanupFlowViewModel(
                buildPlan: sl(), execute: sl(), checkBlocking: sl(), notifier: sl(),
                scan: scan, selection: selection, settings: settings, history: history, router: router)
            viewModel = model
            model.handle(.appear)
        }
    }

    private var checking: some View {
        ProgressView()
            .controlSize(.small)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
    }

    @ViewBuilder
    private func content(_ vm: CleanupFlowViewModel) -> some View {
        switch vm.stage {
        case .checking:
            checking
        case .review:
            ReviewContent(
                totalText: vm.totalText, countText: vm.countText,
                regenerateHeader: vm.regenerateHeader, regenerateRows: vm.regenerateRows,
                costHeader: vm.costHeader, costRows: vm.costRows, commands: vm.commands,
                movesToTrash: vm.movesToTrash, needsUnderstanding: vm.needsUnderstanding,
                understands: vm.understands, primaryTitle: vm.primaryTitle, canClean: vm.canClean,
                onToggleTrash: { vm.handle(.setMovesToTrash(!vm.movesToTrash)) },
                onToggleUnderstands: { vm.handle(.toggleUnderstands) },
                onCancel: { vm.handle(.dismiss) },
                onClean: { vm.handle(.confirm) })
        case .blocked:
            BlockedContent(
                apps: vm.blockingApps, isRechecking: vm.isRechecking,
                onCancel: { vm.handle(.dismiss) }, onRecheck: { vm.handle(.recheck) })
        case .progress:
            ProgressContent(
                fraction: vm.progressFraction, freedText: vm.freedText, ofTotalText: vm.ofTotalText,
                stepText: vm.stepText, onCancel: { vm.handle(.cancelCleanup) })
        case .result:
            ResultContent(
                freedText: vm.resultFreedText, countText: vm.resultCountText,
                wasCancelled: vm.wasCancelled, showsTrashNote: vm.showsTrashNote,
                failureHeader: vm.failureHeader, failures: vm.failureRows,
                isFailuresExpanded: vm.isFailuresExpanded,
                onToggleFailures: { vm.handle(.toggleFailures) },
                onShowInFinder: { vm.handle(.showInFinder($0)) },
                onShowHistory: { vm.handle(.finish(showHistory: true)) },
                onDone: { vm.handle(.finish(showHistory: false)) })
        }
    }
}
