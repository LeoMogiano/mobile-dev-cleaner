import Foundation

/// Turns the current selection into ordered operations (sidebar order, then report order).
struct BuildCleanupPlanUseCase: Sendable {
    func callAsFunction(
        reports: [CategoryID: CategoryReport],
        candidateIDs: Set<String>,
        deviceActions: [String: DeviceAction]
    ) -> [CleanupOperation] {
        CategoryID.allCases.flatMap { id -> [CleanupOperation] in
            guard let report = reports[id] else { return [] }
            let candidates = report.candidates
                .filter { candidateIDs.contains($0.id) }
                .map(Self.operation(for:))
            let devices = report.devices.compactMap { device in
                deviceActions[device.id].flatMap { Self.operation(for: device, action: $0) }
            }
            return candidates + devices
        }
    }

    private static func operation(for candidate: CleanupCandidate) -> CleanupOperation {
        CleanupOperation(
            id: candidate.id,
            category: candidate.category,
            name: candidate.name,
            size: candidate.size,
            risk: candidate.risk,
            note: candidate.cost.map { "\(candidate.name): \($0.lowercasedFirst)" },
            source: .candidate,
            steps: [candidate.execution],
            url: candidate.url
        )
    }

    private static func operation(for device: DeviceCandidate, action: DeviceAction) -> CleanupOperation? {
        guard let plan = device.plan(for: action) else { return nil }
        let note: String? = switch action {
        case .clean: nil
        case .reset: L10n.string("\(device.name): quedará como recién creado. Se pierden sus apps y datos.")
        case .delete: L10n.string("\(device.name): se borra el dispositivo completo. Podrás crearlo de nuevo.")
        }
        return CleanupOperation(
            id: device.id,
            category: device.category,
            name: "\(device.name) · \(action.title)",
            size: plan.freedBytes,
            risk: plan.risk,
            note: note,
            source: .device(action),
            steps: plan.steps,
            url: device.url
        )
    }
}

extension DeviceAction {
    var title: String {
        switch self {
        case .clean: L10n.string("Limpiar")
        case .reset: L10n.string("Restablecer")
        case .delete: L10n.string("Eliminar")
        }
    }
}

private extension String {
    var lowercasedFirst: String { prefix(1).lowercased() + dropFirst() }
}
