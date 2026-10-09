import SwiftUI

struct CreatorSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack(alignment: .center, spacing: 12) {
                    ZStack(alignment: .center) {
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(hex: 0x8fd3ff), location: 0),
                                .init(color: Color(hex: 0x3a8bff), location: 0.38),
                                .init(color: Color(hex: 0x6b5cff), location: 0.70),
                                .init(color: Color(hex: 0xb45cff), location: 1)
                            ]),
                            center: .init(x: 0.30, y: 0.25),
                            startRadius: 0,
                            endRadius: 22
                        )
                        .frame(width: 44, height: 44)
                        .cornerRadius(22)

                        Text("LM")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.white)
                    }

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
}
