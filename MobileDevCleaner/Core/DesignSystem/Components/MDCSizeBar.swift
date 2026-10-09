import SwiftUI

struct MDCSizeBar: View {
    /// 0...1 relative to the biggest item in the list.
    let fraction: Double
    var tint: Color = .mdcAccent
    var width: CGFloat = 90
    var height: CGFloat = 4

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: height / 2)
                .fill(Color.mdcFill)

            let clampedFraction = min(max(fraction, 0), 1)
            let minVisible: CGFloat = 2
            let fillWidth = clampedFraction > 0 ? max(width * clampedFraction, minVisible) : 0

            RoundedRectangle(cornerRadius: height / 2)
                .fill(tint)
                .frame(width: fillWidth)
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 16) {
        MDCSizeBar(fraction: 0.3)
        MDCSizeBar(fraction: 0.7, tint: .mdcXcode)
        MDCSizeBar(fraction: 0.1, tint: .mdcAndroid)
        MDCSizeBar(fraction: 0, tint: .mdcRegen)
        MDCSizeBar(fraction: 1, tint: .mdcCost)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .controlBackgroundColor))
}
