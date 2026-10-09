import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("AppLanguage")
struct AppLanguageTests {
    @Test("es locale identifier")
    func esLocaleIdentifier() {
        let locale = AppLanguage.es.locale
        #expect(locale.identifier == "es")
    }

    @Test("en locale identifier")
    func enLocaleIdentifier() {
        let locale = AppLanguage.en.locale
        #expect(locale.identifier == "en")
    }

    @Test("system locale is autoupdating current")
    func systemLocaleIsAutoupdatingCurrent() {
        let locale = AppLanguage.system.locale
        #expect(locale.identifier == Locale.autoupdatingCurrent.identifier)
    }

    @Test("es bundle code")
    func esBundleCode() {
        let code = AppLanguage.es.bundleCode
        #expect(code == "es")
    }

    @Test("en bundle code")
    func enBundleCode() {
        let code = AppLanguage.en.bundleCode
        #expect(code == "en")
    }

    @Test("system bundle code is nil")
    func systemBundleCodeIsNil() {
        let code = AppLanguage.system.bundleCode
        #expect(code == nil)
    }

    @Test("es display name")
    func esDisplayName() {
        let name = AppLanguage.es.displayName
        #expect(name == "Español")
    }

    @Test("en display name")
    func enDisplayName() {
        let name = AppLanguage.en.displayName
        #expect(name == "English")
    }

    @Test("system display name is localized")
    func systemDisplayNameIsLocalized() {
        let name = AppLanguage.system.displayName
        #expect(!name.isEmpty)
    }

    @Test("es raw value round-trip")
    func esRawValueRoundTrip() {
        let original = AppLanguage.es
        let rawValue = original.rawValue
        let restored = AppLanguage(rawValue: rawValue)
        #expect(restored == original)
    }

    @Test("en raw value round-trip")
    func enRawValueRoundTrip() {
        let original = AppLanguage.en
        let rawValue = original.rawValue
        let restored = AppLanguage(rawValue: rawValue)
        #expect(restored == original)
    }

    @Test("system raw value round-trip")
    func systemRawValueRoundTrip() {
        let original = AppLanguage.system
        let rawValue = original.rawValue
        let restored = AppLanguage(rawValue: rawValue)
        #expect(restored == original)
    }

    @Test("es id equals raw value")
    func esIdEqualsRawValue() {
        let language = AppLanguage.es
        #expect(language.id == language.rawValue)
        #expect(language.id == "es")
    }

    @Test("en id equals raw value")
    func enIdEqualsRawValue() {
        let language = AppLanguage.en
        #expect(language.id == language.rawValue)
        #expect(language.id == "en")
    }

    @Test("system id equals raw value")
    func systemIdEqualsRawValue() {
        let language = AppLanguage.system
        #expect(language.id == language.rawValue)
        #expect(language.id == "system")
    }

    @Test("all cases count")
    func allCasesCount() {
        #expect(AppLanguage.allCases.count == 3)
    }

    @Test("all cases contains expected values")
    func allCasesContainsExpectedValues() {
        let cases = Set(AppLanguage.allCases.map { $0.rawValue })
        #expect(cases.contains("system"))
        #expect(cases.contains("es"))
        #expect(cases.contains("en"))
    }
}
