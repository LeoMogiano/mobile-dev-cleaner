import AppKit
import SwiftUI

/// Colors from `applyVars()` in the prototype. Material-dependent surfaces live in `MDCSurface`.
extension Color {
    static let mdcAccent = Color(light: 0x007AFF, dark: 0x0A84FF)
    static let mdcAccentInk = Color(light: 0x0062CC, dark: 0x64B0FF)
    static let mdcAccentBg = Color(light: (0x007AFF, 0.12), dark: (0x0A84FF, 0.24))

    static let mdcRegen = Color(light: 0x34C759, dark: 0x30D158)
    // 5.44:1 on mdcRegenBg (light).
    static let mdcRegenInk = Color(light: 0x17703A, dark: 0x30D158)
    static let mdcRegenBg = Color(light: (0x34C759, 0.15), dark: (0x30D158, 0.18))

    static let mdcCost = Color(light: 0xFF9F0A, dark: 0xFFB340)
    static let mdcCostInk = Color(light: 0xA35200, dark: 0xFFB340)
    static let mdcCostBg = Color(light: (0xFF9F0A, 0.17), dark: (0xFFB340, 0.18))

    static let mdcProtected = Color(light: 0x8E8E93, dark: 0x98989D)
    static let mdcProtectedBg = Color(light: (0x8E8E93, 0.16), dark: (0x98989D, 0.2))
    static let mdcDestructive = Color(light: 0xFF3B30, dark: 0xFF453A)
    /// Destructive text: 5.38:1 on white, 5.91:1 on #1E1E1E.
    static let mdcDestructiveInk = Color(light: 0xD70015, dark: 0xFF6961)
    static let mdcSnapshots = Color(light: 0xAF52DE, dark: 0xBF5AF2)

    static let mdcXcode = Color(light: 0x1575F9, dark: 0x1575F9)
    static let mdcAndroid = Color(light: 0x2DB86B, dark: 0x2FA66A)
    static let mdcFlutter = Color(light: 0x027DFD, dark: 0x027DFD)

    static let mdcText1 = Color(light: (0x000000, 0.86), dark: (0xFFFFFF, 0.92))
    static let mdcText2 = Color(
        light: (0x000000, 0.60), dark: (0xFFFFFF, 0.64),
        highContrastLight: (0x000000, 0.80), highContrastDark: (0xFFFFFF, 0.80))
    // 4.94:1 on white and 5.12:1 on #1E1E1E (WCAG AA for body text).
    static let mdcText3 = Color(
        light: (0x000000, 0.56), dark: (0xFFFFFF, 0.50),
        highContrastLight: (0x000000, 0.72), highContrastDark: (0xFFFFFF, 0.72))

    static let mdcLine = Color(
        light: (0x000000, 0.08), dark: (0xFFFFFF, 0.09),
        highContrastLight: (0x000000, 0.30), highContrastDark: (0xFFFFFF, 0.30))
    static let mdcLine2 = Color(
        light: (0x000000, 0.15), dark: (0xFFFFFF, 0.18),
        highContrastLight: (0x000000, 0.40), highContrastDark: (0xFFFFFF, 0.40))
    static let mdcHover = Color(light: (0x000000, 0.045), dark: (0xFFFFFF, 0.06))
    static let mdcFill = Color(light: (0x000000, 0.07), dark: (0xFFFFFF, 0.10))
    static let mdcSegment = Color(light: (0x000000, 0.06), dark: (0xFFFFFF, 0.08))
    static let mdcSegmentOn = Color(light: (0xFFFFFF, 1), dark: (0xFFFFFF, 0.22))

    static func mdcTool(_ tool: Tool) -> Color {
        switch tool {
        case .xcode: .mdcXcode
        case .android: .mdcAndroid
        case .flutter: .mdcFlutter
        }
    }
}

extension Color {
    /// Fixed sRGB color for illustrations (gradients, brand tiles) that don't follow the theme.
    init(hex: UInt32) {
        self.init(
            .sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }

    init(light: UInt32, dark: UInt32) {
        self.init(light: (light, 1), dark: (dark, 1))
    }

    init(
        light: (UInt32, Double), dark: (UInt32, Double),
        highContrastLight: (UInt32, Double)? = nil, highContrastDark: (UInt32, Double)? = nil
    ) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [
                .aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua,
            ])
            let isDark = match == .darkAqua || match == .accessibilityHighContrastDarkAqua
            let isHighContrast = match == .accessibilityHighContrastAqua || match == .accessibilityHighContrastDarkAqua
            let highContrast = isHighContrast ? (isDark ? highContrastDark : highContrastLight) : nil
            let (hex, alpha) = highContrast ?? (isDark ? dark : light)
            return NSColor(
                srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: alpha
            )
        })
    }
}
