import Foundation

/// User preferences backed by UserDefaults. Keys are stable; Ajustes edits them in F7.
@MainActor @Observable
final class SettingsStore {
    enum Key {
        static let showEmpty = "general.showEmpty"
        static let excludedPaths = "general.excludedPaths"
        static let moveToTrash = "safety.moveToTrash"
        static let confirmCost = "safety.confirmCost"
        static let showTechnicalNames = "advanced.showTechnicalNames"
        static let showCommands = "advanced.showCommands"
    }

    private let defaults: UserDefaults

    var showEmpty: Bool { didSet { defaults.set(showEmpty, forKey: Key.showEmpty) } }
    /// Folders never marked, not even by "Limpieza recomendada".
    var excludedPaths: [String] { didSet { defaults.set(excludedPaths, forKey: Key.excludedPaths) } }
    var moveToTrash: Bool { didSet { defaults.set(moveToTrash, forKey: Key.moveToTrash) } }
    var confirmCost: Bool { didSet { defaults.set(confirmCost, forKey: Key.confirmCost) } }
    var showTechnicalNames: Bool { didSet { defaults.set(showTechnicalNames, forKey: Key.showTechnicalNames) } }
    var showCommands: Bool { didSet { defaults.set(showCommands, forKey: Key.showCommands) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Key.moveToTrash: true, Key.confirmCost: true])
        showEmpty = defaults.bool(forKey: Key.showEmpty)
        excludedPaths = defaults.stringArray(forKey: Key.excludedPaths) ?? []
        moveToTrash = defaults.bool(forKey: Key.moveToTrash)
        confirmCost = defaults.bool(forKey: Key.confirmCost)
        showTechnicalNames = defaults.bool(forKey: Key.showTechnicalNames)
        showCommands = defaults.bool(forKey: Key.showCommands)
    }

    func isExcluded(_ path: String) -> Bool {
        excludedPaths.contains { path == $0 || path.hasPrefix($0.hasSuffix("/") ? $0 : $0 + "/") }
    }
}
