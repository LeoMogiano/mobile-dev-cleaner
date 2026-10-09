import SwiftUI

struct SettingsLinkRow: View {
    let icon: Image
    let iconColor: Color
    let background: AnyShapeStyle
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let url: String

    var body: some View {
        Link(destination: URL(string: url) ?? URL(fileURLWithPath: "")) {
            HStack(alignment: .center, spacing: 11) {
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(background)
                        .frame(width: 26, height: 26)

                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.mdcText1)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.mdcText3)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mdcText3)
            }
            .contentShape(Rectangle())
        }
    }
}
