import SwiftUI

struct SidebarWordmark: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "trash")
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0x3A / 255, green: 0xA0 / 255, blue: 1), location: 0),
                            .init(color: Color(red: 0x5B / 255, green: 0x6C / 255, blue: 1), location: 0.55),
                            .init(color: Color(red: 0xA3 / 255, green: 0x5B / 255, blue: 1), location: 1),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
                .accessibilityHidden(true)
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
