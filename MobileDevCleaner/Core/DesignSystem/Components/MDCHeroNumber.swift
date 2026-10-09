import SwiftUI

struct MDCHeroNumber: View {
    let bytes: Int64
    /// Count-up on appear and on change; off when Reduce Motion is on.
    var animates = true

    @State private var shown: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CountingText(value: shown)
            .accessibilityElement()
            .accessibilityLabel("Puedes recuperar \(ByteFormatter.string(bytes, locale: AppLanguage.current.locale))")
            .onAppear { update(to: bytes) }
            .onChange(of: bytes) { _, newValue in update(to: newValue) }
    }

    private func update(to target: Int64) {
        guard animates, !reduceMotion else {
            shown = Double(target)
            return
        }
        // Cubic ease-out over 1.1 s, as countUp() in the prototype.
        withAnimation(.timingCurve(0.33, 1, 0.68, 1, duration: 1.1)) {
            shown = Double(target)
        }
    }
}

/// Animatable so SwiftUI interpolates the byte count; only this text redraws per frame.
private struct CountingText: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        let (number, unit) = ByteFormatter.parts(Int64(value), locale: AppLanguage.current.locale)
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(number)
                .font(.mont(60, weight: .bold))
                .tracking(-2.7)
                .monospacedDigit()
            Text(unit)
                .font(.mont(26, weight: .bold))
                .tracking(-0.52)
        }
        .lineLimit(1)
        .fixedSize()
    }
}

#Preview {
    VStack(spacing: 20) {
        MDCHeroNumber(bytes: 37_700_000_000, animates: false)
        MDCHeroNumber(bytes: 0, animates: false)
        MDCHeroNumber(bytes: 500_000_000, animates: false)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .controlBackgroundColor))
}
