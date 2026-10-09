import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case es
    case en

    var id: String { rawValue }

    static let storageKey = "appLanguage"

    /// Effective locale: the system one for .system.
    var locale: Locale {
        self == .system ? .autoupdatingCurrent : Locale(identifier: rawValue)
    }

    /// lproj code for strings outside SwiftUI (nil = whatever macOS picked at launch).
    var bundleCode: String? {
        self == .system ? nil : rawValue
    }

    /// Name in its own language; only .system is localized.
    var displayName: String {
        switch self {
        case .system: L10n.string("Del sistema")
        case .es: "Español"
        case .en: "English"
        }
    }

    static var current: AppLanguage {
        get {
            if let raw = UserDefaults.standard.string(forKey: storageKey),
               let language = AppLanguage(rawValue: raw) {
                return language
            }
            return .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
            newValue.apply()
        }
    }

    /// Writes AppleLanguages so system menus and the next launch use the language.
    func apply() {
        if self == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([rawValue], forKey: "AppleLanguages")
        }
    }
}
