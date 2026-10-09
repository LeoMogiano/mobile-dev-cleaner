import SwiftUI

struct CreatorSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack(alignment: .center, spacing: 12) {
                    Group {
                        if let photo = Self.photo {
                            Image(nsImage: photo).resizable().scaledToFill()
                        } else {
                            Text("LM")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.mdcAccent)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Leo Mogiano")
                            .font(.mont(14, weight: .semibold))
                            .tracking(-0.14)
                        Text("AI Mobile Dev Enthusiast · Hice esta app porque mi Mac se quedaba sin espacio cada semana.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Color.mdcText2)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(.vertical, 2)

                SettingsLinkRow(
                    icon: Image("github"),
                    iconColor: Color.white,
                    background: AnyShapeStyle(Color(hex: 0x1b1f24)),
                    title: "GitHub",
                    detail: "LeoMogiano",
                    url: "https://github.com/LeoMogiano"
                )

                SettingsLinkRow(
                    icon: Image("linkedin"),
                    iconColor: Color.white,
                    background: AnyShapeStyle(Color(hex: 0x0a66c2)),
                    title: "LinkedIn",
                    detail: "leomogiano",
                    url: "https://linkedin.com/in/leomogiano"
                )

                SettingsLinkRow(
                    icon: Image(systemName: "cup.and.saucer.fill"),
                    iconColor: Color(hex: 0x3d2b00),
                    background: AnyShapeStyle(Color(hex: 0xffcc00)),
                    title: "Invítame un café",
                    detail: "Si te ahorró espacio",
                    url: "https://buymeacoffee.com/leomogiano"
                )
            }
        }
        .formStyle(.grouped)
    }

    private static let photo: NSImage? = Bundle.main.url(forResource: "creator", withExtension: "webp")
        .flatMap(NSImage.init(contentsOf:))
}
