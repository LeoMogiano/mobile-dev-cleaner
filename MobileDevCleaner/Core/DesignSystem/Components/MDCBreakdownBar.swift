import SwiftUI

struct MDCBreakdownBar: View {
    struct Segment: Identifiable, Hashable {
        let id: String
        let value: Int64
        let color: Color
    }

    let segments: [Segment]
    var height: CGFloat = 7
    var gap: CGFloat = 0

    var body: some View {
        let visible = segments.filter { $0.value > 0 }
        let total = visible.reduce(Int64(0)) { $0 + $1.value }
        GeometryReader { proxy in
            let available = max(0, proxy.size.width - gap * CGFloat(max(0, visible.count - 1)))
            HStack(spacing: gap) {
                ForEach(visible) { segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: available * CGFloat(segment.value) / CGFloat(max(total, 1)))
                }
            }
        }
        .frame(height: height)
        .background(Color.mdcFill)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        MDCBreakdownBar(
            segments: [
                .init(id: "regen", value: 48_000_000_000, color: .mdcRegen),
                .init(id: "cost", value: 52_000_000_000, color: .mdcCost)
            ],
            height: 12,
            gap: 2
        )

        MDCBreakdownBar(
            segments: [
                .init(id: "a", value: 30_000_000_000, color: .mdcXcode),
                .init(id: "b", value: 40_000_000_000, color: .mdcAndroid),
                .init(id: "c", value: 30_000_000_000, color: .mdcRegen)
            ],
            height: 7,
            gap: 0
        )

        MDCBreakdownBar(
            segments: [
                .init(id: "only", value: 100_000_000_000, color: .mdcCost)
            ],
            height: 7,
            gap: 0
        )

        MDCBreakdownBar(segments: [], height: 7, gap: 0)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .controlBackgroundColor))
}
