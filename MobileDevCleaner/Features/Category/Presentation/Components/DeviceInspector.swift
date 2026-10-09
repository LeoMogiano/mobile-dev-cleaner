import SwiftUI

struct DeviceInspector: View {
    let device: DeviceCandidate
    let action: DeviceAction?
    let showsCommand: Bool
    let movesToTrash: Bool
    let onShowInFinder: () -> Void
    let onClose: () -> Void

    private var badge: MDCBadgeKind {
        action == .clean ? .regenerates : .hasCost
    }

    private var idLabel: String {
        device.category == .avds ? "Nombre del AVD" : "UDID"
    }

    private var commandValue: String? {
        guard showsCommand, let action else { return nil }
        guard let plan = device.plan(for: action) else { return nil }
        let commands = plan.steps.map { $0.commandLine(movesToTrash: movesToTrash) }
        return commands.joined(separator: "\n")
    }

    var body: some View {
        VStack(spacing: 0) {
            InspectorHeader(
                name: device.name,
                badge: badge,
                onClose: onClose
            )
            ScrollView {
                VStack(spacing: 14) {
                    if device.isRunning {
                        InspectorField(label: "Estado", value: "En uso: ciérralo para poder limpiarlo")
                    }
                    InspectorField(label: "Sistema", value: device.osVersion)
                    InspectorField(label: idLabel, value: device.id, isMono: true)
                    InspectorField(label: "Tamaño total", value: ByteFormatter.string(device.sizes.total))
                    InspectorField(label: "Datos de apps", value: ByteFormatter.string(device.sizes.data))
                    InspectorField(label: "Caché", value: ByteFormatter.string(device.sizes.cache))
                    InspectorField(label: "Snapshots", value: ByteFormatter.string(device.sizes.snapshots))
                    let actionLabel: String = {
                        guard let action else { return "Ninguna" }
                        return action == .clean ? "Limpiar" : action == .reset ? "Restablecer" : "Eliminar"
                    }()
                    InspectorField(label: "Acción elegida", value: actionLabel)
                    if let cmd = commandValue {
                        InspectorField(label: "Comando", value: cmd, isMono: true)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity)
            InspectorFooter(
                markLabel: nil,
                onShowInFinder: onShowInFinder,
                onMark: nil
            )
        }
    }
}
