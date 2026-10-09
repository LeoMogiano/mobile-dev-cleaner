import AppKit
import SwiftUI

/// Colors from `applyVars()` in the prototype. Material-dependent surfaces live in `MDCSurface`.
extension Color {
    static let mdcAccent = Color(light: 0x007AFF, dark: 0x0A84FF)
    static let mdcAccentInk = Color(light: 0x0062CC, dark: 0x64B0FF)
    static let mdcAccentBg = Color(light: (0x007AFF, 0.12), dark: (0x0A84FF, 0.24))

    static let mdcRegen = Color(light: 0x34C759, dark: 0x30D158)
    static let mdcRegenInk = Color(light: 0x1A7F37, dark: 0x30D158)
    static let mdcRegenBg = Color(light: (0x34C759, 0.15), dark: (0x30D158, 0.18))

    static let mdcCost = Color(light: 0xFF9F0A, dark: 0xFFB340)
    static let mdcCostInk = Color(light: 0xA35200, dark: 0xFFB340)
    static let mdcCostBg = Color(light: (0xFF9F0A, 0.17), dark: (0xFFB340, 0.18))

    static let mdcProtected = Color(light: 0x8E8E93, dark: 0x98989D)
    static let mdcProtectedBg = Color(light: (0x8E8E93, 0.16), dark: (0x98989D, 0.2))
    static let mdcDestructive = Color(light: 0xFF3B30, dark: 0xFF453A)
    static let mdcSnapshots = Color(light: 0xAF52DE, dark: 0xBF5AF2)

    static let mdcXcode = Color(light: 0x1575F9, dark: 0x1575F9)
    static let mdcAndroid = Color(light: 0x2DB86B, dark: 0x2FA66A)
    static let mdcFlutter = Color(light: 0x027DFD, dark: 0x027DFD)

    static let mdcText1 = Color(light: (0x000000, 0.86), dark: (0xFFFFFF, 0.92))
    static let mdcText2 = Color(light: (0x000000, 0.60), dark: (0xFFFFFF, 0.64))
    static let mdcText3 = Color(light: (0x000000, 0.44), dark: (0xFFFFFF, 0.44))

    static let mdcLine = Color(light: (0x000000, 0.08), dark: (0xFFFFFF, 0.09))
    static let mdcLine2 = Color(light: (0x000000, 0.15), dark: (0xFFFFFF, 0.18))
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

    init(light: (UInt32, Double), dark: (UInt32, Double)) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let (hex, alpha) = isDark ? dark : light
            return NSColor(
                srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: alpha
            )
        })
    }
}
