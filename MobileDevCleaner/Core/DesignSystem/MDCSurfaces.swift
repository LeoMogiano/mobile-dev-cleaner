import SwiftUI

extension View {
    func mdcCard(radius: CGFloat = 14) -> some View {
        modifier(SurfaceModifier(kind: .card, radius: radius))
    }

    /// `radius` nil = pill on Liquid Glass, 6 on Clásico.
    func mdcControl(radius: CGFloat? = nil) -> some View {
        modifier(SurfaceModifier(kind: .control, radius: radius))
    }

    func mdcInner(radius: CGFloat = 10) -> some View {
        modifier(SurfaceModifier(kind: .inner, radius: radius))
    }
}

/// Surface tokens from the tahoe and classic branches of `applyVars()`.
private struct SurfaceModifier: ViewModifier {
    enum Kind { case card, control, inner }

    let kind: Kind
    let radius: CGFloat?
    @Environment(\.mdcMaterial) private var material

    func body(content: Content) -> some View {
        let glass = material.usesGlass
        let shape = RoundedRectangle(cornerRadius: radius ?? (glass ? 999 : 6), style: .continuous)
        let style = glass ? Self.glass[kind]! : Self.classic[kind]!
        content
            .background(style.fill, in: shape)
            .overlay(shape.strokeBorder(style.border, lineWidth: 0.5))
            .shadow(color: style.shadow, radius: style.shadowRadius, x: 0, y: style.shadowY)
    }

    private struct Style {
        let fill: Color
        let border: Color
        var shadow: Color = .clear
        var shadowRadius: CGFloat = 0
        var shadowY: CGFloat = 0
    }

    private static let glass: [Kind: Style] = [
        // Softer than the web mock: content cards stay calm and let the system glass
        // (sidebar, toolbar) carry the Liquid Glass look, as in System Settings.
        .card: Style(
            fill: Color(light: (0xFFFFFF, 0.5), dark: (0xFFFFFF, 0.05)),
            border: Color(light: (0x000000, 0.05), dark: (0xFFFFFF, 0.07)),
            shadow: Color(light: (0x3C2878, 0.04), dark: (0x000000, 0.12)), shadowRadius: 6, shadowY: 2
        ),
        .control: Style(
            fill: Color(light: (0xFFFFFF, 0.62), dark: (0xFFFFFF, 0.1)),
            border: Color(light: (0xFFFFFF, 0.9), dark: (0xFFFFFF, 0.16)),
            shadow: Color(light: (0x000000, 0.08), dark: (0x000000, 0.3)), shadowRadius: 1.5, shadowY: 1
        ),
        .inner: Style(
            fill: Color(light: (0xFFFFFF, 0.55), dark: (0xFFFFFF, 0.05)),
            border: .clear
        ),
    ]

    private static let classic: [Kind: Style] = [
        .card: Style(
            fill: Color(light: 0xF5F5F7, dark: 0x2C2C2E),
            border: Color(light: (0x000000, 0.06), dark: (0xFFFFFF, 0.06))
        ),
        .control: Style(
            fill: Color(light: 0xFFFFFF, dark: 0x48484A),
            border: Color(light: (0x000000, 0.16), dark: (0xFFFFFF, 0.08)),
            shadow: Color(light: (0x000000, 0.08), dark: (0x000000, 0.3)), shadowRadius: 0.5, shadowY: 0.5
        ),
        .inner: Style(fill: Color(light: 0xFFFFFF, dark: 0x323234), border: .clear),
    ]
}

