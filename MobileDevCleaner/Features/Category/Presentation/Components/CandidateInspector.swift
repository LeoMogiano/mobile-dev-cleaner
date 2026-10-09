import SwiftUI

struct CandidateInspector: View {
    let candidate: CleanupCandidate
    let isSelected: Bool
    let showsCommand: Bool
    let movesToTrash: Bool
    let onToggle: () -> Void
    let onShowInFinder: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            InspectorHeader(
                name: candidate.name,
                badge: MDCBadgeKind(candidate.risk),
                onClose: onClose
            )
            ScrollView {
                VStack(spacing: 14) {
                    InspectorField(label: "Ruta completa", value: candidate.url.path, isMono: true)
                    InspectorField(label: "Tamaño", value: ByteFormatter.string(candidate.size))
                    if let mod = candidate.modifiedAt {
                        InspectorField(label: "Última modificación", value: InspectorDateFormat.string(for: mod))
                    }
                    let info = CategoryInfo.info(for: candidate.category)
                    InspectorField(label: "Por qué aparece", value: candidate.reason ?? info.whatIsIt)
                    InspectorField(label: "Qué pasa si lo borro", value: candidate.cost ?? info.ifDeleted)
                    InspectorField(label: "¿Vuelve a aparecer?", value: info.comesBack)
                    if showsCommand {
                        InspectorField(label: "Comando", value: candidate.execution.commandLine(movesToTrash: movesToTrash), isMono: true)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity)
            InspectorFooter(
                markLabel: isSelected ? L10n.string("Desmarcar") : L10n.string("Marcar"),
                onShowInFinder: onShowInFinder,
                onMark: onToggle
            )
        }
    }
}
