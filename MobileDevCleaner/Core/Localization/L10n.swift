import Foundation

/// Localized strings outside SwiftUI that must follow the in-app language immediately.
/// Use it for Failure.message, accessibility labels built in ViewModels, etc.
enum L10n {
    /// Resolves a key with the current app language, falling back to the system choice.
    /// The locale is passed explicitly so plural rules match the chosen language.
    static func string(_ key: String.LocalizationValue) -> String {
        if let code = AppLanguage.current.bundleCode,
           let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return String(localized: key, bundle: bundle, locale: AppLanguage.current.locale)
        }
        return String(localized: key)
    }
}
