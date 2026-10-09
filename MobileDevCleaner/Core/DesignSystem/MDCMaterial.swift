import SwiftUI

/// "Liquid Glass (Tahoe)" or "Clásico" (Ajustes › Apariencia).
enum MDCMaterial: String, CaseIterable, Sendable {
    case liquidGlass
    case classic

    static let storageKey = "appearance.material"

    /// Liquid Glass falls back to classic surfaces before macOS 26.
    var usesGlass: Bool {
        guard self == .liquidGlass else { return false }
        if #available(macOS 26, *) { return true }
        return false
    }
}

extension EnvironmentValues {
    @Entry var mdcMaterial: MDCMaterial = .liquidGlass
}
