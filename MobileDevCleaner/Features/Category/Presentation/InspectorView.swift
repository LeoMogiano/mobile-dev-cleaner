import SwiftUI

struct InspectorView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ScanStore.self) private var scan
    @Environment(SelectionStore.self) private var selection
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        if let id = router.inspectedID {
            if let candidate = findCandidate(id) {
                candidateInspector(candidate)
            } else if let device = findDevice(id) {
                deviceInspector(device)
            } else {
                emptyState
            }
        } else {
            emptyState
        }
    }
    private func candidateInspector(_ candidate: CleanupCandidate) -> some View {
        VStack(spacing: 0) {
            headerView(candidate.name, risk: candidate.risk)
            ScrollView {
                VStack(spacing: 14) {
                    fieldView("Ruta completa", value: candidate.url.path, isMono: true)
                    fieldView("Tamaño", value: ByteFormatter.string(candidate.size))
                    if let mod = candidate.modifiedAt {
                        fieldView("Última modificación", value: formatDate(mod))
                    }
                    let info = CategoryInfo.info(for: candidate.category)
                    fieldView("Por qué aparece", value: candidate.reason ?? info.whatIsIt)
                    fieldView("Qué pasa si lo borro", value: candidate.cost ?? info.ifDeleted)
                    fieldView("¿Vuelve a aparecer?", value: info.comesBack)
                    if settings.showCommands {
                        fieldView("Comando", value: candidate.execution.commandLine(movesToTrash: settings.moveToTrash), isMono: true)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity)
            buttonsView(isCandidate: true, candidate: candidate)
        }
    }
    private func deviceInspector(_ device: DeviceCandidate) -> some View {
        let action = selection.action(for: device)
        let actionLabel: String = {
            guard let action else { return "Ninguna" }
            return action == .clean ? "Limpiar" : action == .reset ? "Restablecer" : "Eliminar"
        }()
        let risk: RiskLevel = {
            guard let action, let plan = device.plan(for: action) else { return .regenerates }
            return plan.risk
        }()

        return VStack(spacing: 0) {
            headerView(device.name, risk: risk)
            ScrollView {
                VStack(spacing: 14) {
                    fieldView("Sistema", value: device.osVersion)
                    fieldView(device.kind == .phone || device.kind == .tablet ? "Nombre del AVD" : "UDID", value: device.id, isMono: true)
                    fieldView("Tamaño total", value: ByteFormatter.string(device.sizes.total))
                    fieldView("Datos de apps", value: ByteFormatter.string(device.sizes.data))
                    fieldView("Caché", value: ByteFormatter.string(device.sizes.cache))
                    fieldView("Snapshots", value: ByteFormatter.string(device.sizes.snapshots))
                    fieldView("Acción elegida", value: actionLabel)
                    if settings.showCommands, let action, let plan = device.plan(for: action) {
                        fieldView("Comando", value: plan.steps.first?.commandLine(movesToTrash: settings.moveToTrash) ?? "", isMono: true)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity)
            buttonsView(isCandidate: false, device: device)
        }
    }
    private func headerView(_ name: String, risk: RiskLevel) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                MDCRiskBadge(kind: MDCBadgeKind(risk))
            }
            Spacer()
            Button(action: { router.inspect(nil) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar")
        }
        .foregroundColor(.mdcText1)
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .overlay(alignment: .bottom) { Divider().foregroundColor(.mdcLine) }
    }

    private func fieldView(_ label: String, value: String, isMono: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.mdcText3)
            Text(value)
                .font(.system(size: 12.5, weight: .regular, design: isMono ? .monospaced : .default))
                .foregroundColor(.mdcText1)
                .lineLimit(nil)
        }
    }

    private func buttonsView(isCandidate: Bool, candidate: CleanupCandidate? = nil, device: DeviceCandidate? = nil) -> some View {
        HStack(spacing: 6) {
            Button(action: showInFinder) {
                HStack(spacing: 5) {
                    Image(systemName: "finder")
                        .font(.system(size: 12, weight: .regular))
                    Text("Mostrar en Finder")
                }
            }
            .buttonStyle(MDCSecondaryButtonStyle())

            if isCandidate {
                let isSelected = candidate.map { selection.isSelected($0) } ?? false
                let label = isSelected ? "Desmarcar" : "Marcar"
                Button(label) {
                    candidate.map { selection.toggle($0) }
                }
                .buttonStyle(MDCSecondaryButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .overlay(alignment: .top) { Divider().foregroundColor(.mdcLine) }
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

    private func showInFinder() {
        guard let id = router.inspectedID else { return }
        let path = findCandidate(id)?.url.path ?? findDevice(id)?.url.path
        if let path {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = AppLanguage.current.locale
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
