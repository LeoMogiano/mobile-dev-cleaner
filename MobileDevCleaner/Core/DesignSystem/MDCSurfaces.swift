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
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let glass = material.usesGlass
        let shape = RoundedRectangle(cornerRadius: radius ?? (glass ? 999 : 6), style: .continuous)
        let style = glass ? (reduceTransparency ? Self.opaque[kind]! : Self.glass[kind]!) : Self.classic[kind]!
        content
            .background(style.fill, in: shape)
            .overlay(shape.strokeBorder(style.border, lineWidth: 0.5))
    }

    private struct Style {
        let fill: Color
        let border: Color
    }

    private static let glass: [Kind: Style] = [
        // Flatter than the web mock: no shadows; a faint fill and hairline separate surfaces,
        // and the system glass (sidebar, toolbar) carries the Liquid Glass look.
        .card: Style(
            fill: Color(light: (0xFFFFFF, 0.5), dark: (0xFFFFFF, 0.05)),
            border: Color(light: (0x000000, 0.05), dark: (0xFFFFFF, 0.07))
        ),
        .control: Style(
            fill: Color(light: (0xFFFFFF, 0.62), dark: (0xFFFFFF, 0.1)),
            border: Color(light: (0x000000, 0.1), dark: (0xFFFFFF, 0.16))
        ),
        .inner: Style(
            fill: Color(light: (0xFFFFFF, 0.55), dark: (0xFFFFFF, 0.05)),
            border: .clear
        ),
    ]

    /// Solid stand-ins for the glass fills when Reduce Transparency is on; borders are unchanged.
    private static let opaque: [Kind: Style] = [
        .card: Style(fill: Color(nsColor: .controlBackgroundColor), border: Self.glass[.card]!.border),
        .control: Style(fill: Color(nsColor: .controlBackgroundColor), border: Self.glass[.control]!.border),
        .inner: Style(fill: Color(nsColor: .windowBackgroundColor), border: .clear),
    ]

    private static let classic: [Kind: Style] = [
        .card: Style(
            fill: Color(light: 0xF5F5F7, dark: 0x2C2C2E),
            border: Color(light: (0x000000, 0.06), dark: (0xFFFFFF, 0.06))
        ),
        .control: Style(
            fill: Color(light: 0xFFFFFF, dark: 0x48484A),
            border: Color(light: (0x000000, 0.16), dark: (0xFFFFFF, 0.08))
        ),
        .inner: Style(fill: Color(light: 0xFFFFFF, dark: 0x323234), border: .clear),
    ]
}

