import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack(alignment: .center, spacing: 14) {
                    ZStack(alignment: .center) {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(hex: 0x3aa0ff), location: 0),
                                .init(color: Color(hex: 0x5b6cff), location: 0.55),
                                .init(color: Color(hex: 0xa35bff), location: 1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 56, height: 56)
                        .cornerRadius(14)

                        Image(systemName: "trash.fill")
                            .font(.system(size: 27))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mobile Dev Cleaner")
                            .font(.mont(17, weight: .bold))
                            .tracking(-0.34)
                        Text("Versión \(appVersion) · Licencia MIT · Sin telemetría")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.mdcText2)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Section {
                LinkRow(
                    icon: "star.fill",
                    iconColor: Color(hex: 0xFFA500),
                    backgroundColor: Color(hex: 0xFFF3CD),
                    title: "Dale una estrella en GitHub",
                    detail: "Ayuda a que más devs la encuentren",
                    url: "https://github.com/LeoMogiano/mdc-cli"
                )

                LinkRow(
                    icon: "exclamationmark.triangle",
                    iconColor: Color.mdcText2,
                    backgroundColor: Color.mdcFill,
                    title: "Reportar un problema",
                    detail: "GitHub Issues",
                    url: "https://github.com/LeoMogiano/mdc-cli/issues"
                )
            }

            Section("Creador") {
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

                LinkRow(
                    icon: "chevron.left.forwardslash.chevron.right",
                    iconColor: Color.white,
                    backgroundColor: Color(hex: 0x1b1f24),
                    title: "GitHub",
                    detail: "LeoMogiano",
                    url: "https://github.com/LeoMogiano"
                )

                LinkRow(
                    icon: "text.justify",
                    iconColor: Color.white,
                    backgroundColor: Color(hex: 0x0a66c2),
                    title: "LinkedIn",
                    detail: "leomogiano",
                    url: "https://linkedin.com/in/leomogiano"
                )

                LinkRow(
                    icon: "cup.and.saucer.fill",
                    iconColor: Color(hex: 0x3d2b00),
                    backgroundColor: Color(hex: 0xffcc00),
                    title: "Invítame un café",
                    detail: "Si te ahorró espacio",
                    url: "https://buymeacoffee.com/leomogiano"
                )
            }
        }
        .formStyle(.grouped)
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
    }
}

private struct LinkRow: View {
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let title: String
    let detail: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url) ?? URL(fileURLWithPath: "")) {
            HStack(alignment: .center, spacing: 11) {
                ZStack(alignment: .center) {
                    backgroundColor
                        .frame(width: 26, height: 26)
                        .cornerRadius(7)

                    Image(systemName: icon)
                        .font(.system(size: 13))
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
