import SwiftUI

enum MDCBadgeKind: Hashable {
    case regenerates, hasCost, protected

    init(_ risk: RiskLevel) { self = risk == .regenerates ? .regenerates : .hasCost }
}

struct MDCRiskBadge: View {
    let kind: MDCBadgeKind

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .regular))
                .imageScale(.medium)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(foregroundColor)
        .frame(height: 20)
        .padding(.horizontal, 8)
        .background(backgroundColor)
        .cornerRadius(10)
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
        case .regenerates: "Se regenera solo"
        case .hasCost: "Tiene costo"
        case .protected: "Nunca lo tocamos"
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
