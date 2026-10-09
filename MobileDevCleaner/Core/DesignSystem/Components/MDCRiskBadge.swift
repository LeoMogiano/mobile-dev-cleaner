import SwiftUI

enum MDCBadgeKind: Hashable {
    case regenerates, hasCost, protected

    init(_ risk: RiskLevel) { self = risk == .regenerates ? .regenerates : .hasCost }
}

struct MDCRiskBadge: View {
    let kind: MDCBadgeKind
    /// Row variant: 18 high, 10.5 pt (category rows); default is the 20 pt header badge.
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: compact ? 10 : 11))
            Text(label)
                .font(.system(size: compact ? 10.5 : 11, weight: .semibold))
        }
        .foregroundStyle(foregroundColor)
        .frame(height: compact ? 18 : 20)
        .padding(.horizontal, compact ? 7 : 8)
        .background(backgroundColor, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    private var iconName: String {
        switch kind {
        case .regenerates: "arrow.triangle.2.circlepath"
        case .hasCost: "clock.arrow.circlepath"
        case .protected: "lock.fill"
        }
    }

    private var label: String {
        switch kind {
        case .regenerates: L10n.string("Se regenera solo")
        case .hasCost: L10n.string("Tiene costo")
        case .protected: L10n.string("Nunca lo tocamos")
        }
    }

    private var foregroundColor: Color {
        switch kind {
        case .regenerates: .mdcRegenInk
        case .hasCost: .mdcCostInk
        case .protected: .mdcText2
        }
    }

    private var backgroundColor: Color {
        switch kind {
        case .regenerates: .mdcRegenBg
        case .hasCost: .mdcCostBg
        case .protected: .mdcProtectedBg
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        MDCRiskBadge(kind: .regenerates)
        MDCRiskBadge(kind: .hasCost)
        MDCRiskBadge(kind: .protected)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .controlBackgroundColor))
}
