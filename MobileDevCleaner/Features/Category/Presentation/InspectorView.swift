import SwiftUI

struct InspectorView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ScanStore.self) private var scan
    @Environment(SelectionStore.self) private var selection
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        if let id = router.inspectedID {
            if let candidate = findCandidate(id) {
                CandidateInspector(
                    candidate: candidate,
                    isSelected: selection.isSelected(candidate),
                    showsCommand: settings.showCommands,
                    movesToTrash: settings.moveToTrash,
                    onToggle: { selection.toggle(candidate) },
                    onShowInFinder: { showFinderForCandidate(candidate) },
                    onClose: { router.inspect(nil) }
                )
            } else if let device = findDevice(id) {
                DeviceInspector(
                    device: device,
                    action: selection.action(for: device),
                    showsCommand: settings.showCommands,
                    movesToTrash: settings.moveToTrash,
                    onShowInFinder: { showFinderForDevice(device) },
                    onClose: { router.inspect(nil) }
                )
            } else {
                emptyState
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        Text("Selecciona un elemento para ver sus detalles.")
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.mdcText3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func findCandidate(_ id: String) -> CleanupCandidate? {
        scan.reports.values.flatMap(\.candidates).first { $0.id == id }
    }

    private func findDevice(_ id: String) -> DeviceCandidate? {
        scan.reports.values.flatMap(\.devices).first { $0.id == id }
    }

    private func showFinderForCandidate(_ candidate: CleanupCandidate) {
        NSWorkspace.shared.activateFileViewerSelecting([candidate.url])
    }

    private func showFinderForDevice(_ device: DeviceCandidate) {
        NSWorkspace.shared.activateFileViewerSelecting([device.url])
    }
}
