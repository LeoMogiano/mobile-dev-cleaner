import SwiftUI

struct SidebarWordmark: View {
    var body: some View {
        HStack(spacing: 9) {
            MDCAppIcon(size: 24)
            Text("Mobile Dev Cleaner")
                .font(.mont(13.5))
                .tracking(-0.27)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 12)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
