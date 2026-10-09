import SwiftUI

struct CategoryHeader: View {
    let category: CategoryID
    let sizeText: String
    let badges: [MDCBadgeKind]

    private var info: CategoryInfo { CategoryInfo.info(for: category) }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.mdcTool(info.id.tool))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )

                Image(systemName: info.symbol)
                    .accessibilityHidden(true)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 46, height: 46)
            .flexibleFrame(horizontal: false, vertical: false)

            VStack(alignment: .leading, spacing: 0) {
                Text(info.name)
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .tracking(-0.44)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)

                Text(info.technicalName)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.mdcText3)
                    .lineLimit(1)
                    .padding(.top, 3)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(sizeText)
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .monospacedDigit()
                    .lineLimit(1)

                HStack(spacing: 5) {
                    ForEach(badges, id: \.self) { badge in
                        MDCRiskBadge(kind: badge)
                    }
                }
            }
            .flexibleFrame(horizontal: false, vertical: false)
        }
    }
}

extension View {
    fileprivate func flexibleFrame(horizontal: Bool = true, vertical: Bool = true) -> some View {
        self.frame(maxWidth: horizontal ? .infinity : nil, maxHeight: vertical ? .infinity : nil)
    }
}

#Preview {
    VStack {
        CategoryHeader(
            category: .builds,
            sizeText: "12.5 GB",
            badges: [.regenerates]
        )
        .padding()
    }
}
