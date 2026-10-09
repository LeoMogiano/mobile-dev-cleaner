import AppKit
import SwiftUI

extension Font {
    /// Montserrat for expressive moments only (hero, onboarding titles, wordmark).
    static func mont(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Montserrat", size: size).weight(weight)
    }

    static func mdcMono(_ size: CGFloat = 11) -> Font {
        .system(size: size, design: .monospaced)
    }
}

enum FontRegistrar {
    private static let registered: Void = {
        let urls = ["ttf", "otf"].flatMap { Bundle.main.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? [] }
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    static func registerBundledFonts() {
        _ = registered
    }
}
