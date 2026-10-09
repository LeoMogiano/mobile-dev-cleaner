import Foundation

enum AppTheme: String, CaseIterable, Sendable {
    case light, dark, auto
}

/// User preferences backed by UserDefaults. Keys are stable.
@MainActor @Observable
final class SettingsStore {
    enum Key {
        static let scanXcode = "general.scanXcode"
        static let scanAndroid = "general.scanAndroid"
        static let scanFlutter = "general.scanFlutter"
        static let scanOnOpen = "general.scanOnOpen"
        static let showEmpty = "general.showEmpty"
        static let notifyOnFinish = "general.notifyOnFinish"
        static let excludedPaths = "general.excludedPaths"
        static let moveToTrash = "safety.moveToTrash"
        static let confirmCost = "safety.confirmCost"
        static let theme = "appearance.theme"
        static let showTechnicalNames = "advanced.showTechnicalNames"
        static let showCommands = "advanced.showCommands"
        static let onboardingCompleted = "onboarding.completed"

        static let all = [
            scanXcode, scanAndroid, scanFlutter, scanOnOpen, showEmpty, notifyOnFinish, excludedPaths, moveToTrash,
            confirmCost, theme, showTechnicalNames, showCommands, MDCMaterial.storageKey, AppLanguage.storageKey,
        ]
    }

    private static let registered: [String: Any] = [
        Key.scanXcode: true, Key.scanAndroid: true, Key.scanFlutter: true, Key.scanOnOpen: true,
        Key.moveToTrash: true, Key.confirmCost: true, Key.theme: AppTheme.auto.rawValue,
    ]

    private let defaults: UserDefaults

    var scanXcode: Bool { didSet { defaults.set(scanXcode, forKey: Key.scanXcode) } }
    var scanAndroid: Bool { didSet { defaults.set(scanAndroid, forKey: Key.scanAndroid) } }
    var scanFlutter: Bool { didSet { defaults.set(scanFlutter, forKey: Key.scanFlutter) } }
    var scanOnOpen: Bool { didSet { defaults.set(scanOnOpen, forKey: Key.scanOnOpen) } }
    var showEmpty: Bool { didSet { defaults.set(showEmpty, forKey: Key.showEmpty) } }
    var notifyOnFinish: Bool { didSet { defaults.set(notifyOnFinish, forKey: Key.notifyOnFinish) } }
    /// Folders never marked, not even by "Limpieza recomendada".
    var excludedPaths: [String] { didSet { defaults.set(excludedPaths, forKey: Key.excludedPaths) } }
    var moveToTrash: Bool { didSet { defaults.set(moveToTrash, forKey: Key.moveToTrash) } }
    var confirmCost: Bool { didSet { defaults.set(confirmCost, forKey: Key.confirmCost) } }
    var theme: AppTheme { didSet { defaults.set(theme.rawValue, forKey: Key.theme) } }
    var showTechnicalNames: Bool { didSet { defaults.set(showTechnicalNames, forKey: Key.showTechnicalNames) } }
    var showCommands: Bool { didSet { defaults.set(showCommands, forKey: Key.showCommands) } }
    var onboardingCompleted: Bool { didSet { defaults.set(onboardingCompleted, forKey: Key.onboardingCompleted) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: Self.registered)
        scanXcode = defaults.bool(forKey: Key.scanXcode)
        scanAndroid = defaults.bool(forKey: Key.scanAndroid)
        scanFlutter = defaults.bool(forKey: Key.scanFlutter)
        scanOnOpen = defaults.bool(forKey: Key.scanOnOpen)
        showEmpty = defaults.bool(forKey: Key.showEmpty)
        notifyOnFinish = defaults.bool(forKey: Key.notifyOnFinish)
        excludedPaths = defaults.stringArray(forKey: Key.excludedPaths) ?? []
        moveToTrash = defaults.bool(forKey: Key.moveToTrash)
        confirmCost = defaults.bool(forKey: Key.confirmCost)
        theme = defaults.string(forKey: Key.theme).flatMap(AppTheme.init) ?? .auto
        showTechnicalNames = defaults.bool(forKey: Key.showTechnicalNames)
        showCommands = defaults.bool(forKey: Key.showCommands)
        onboardingCompleted = defaults.bool(forKey: Key.onboardingCompleted)
    }

    var enabledTools: Set<Tool> {
        var tools: Set<Tool> = []
        if scanXcode { tools.insert(.xcode) }
        if scanAndroid { tools.insert(.android) }
        if scanFlutter { tools.insert(.flutter) }
        return tools
    }

    func isExcluded(_ path: String) -> Bool {
        excludedPaths.contains { path == $0 || path.hasPrefix($0.hasSuffix("/") ? $0 : $0 + "/") }
    }

    /// "Restablecer todos los ajustes": back to defaults; never touches the disk or the onboarding flag.
    func reset() {
        Key.all.forEach(defaults.removeObject(forKey:))
        scanXcode = true
        scanAndroid = true
        scanFlutter = true
        scanOnOpen = true
        showEmpty = false
        notifyOnFinish = false
        excludedPaths = []
        moveToTrash = true
        confirmCost = true
        theme = .auto
        showTechnicalNames = false
        showCommands = false
    }
}
