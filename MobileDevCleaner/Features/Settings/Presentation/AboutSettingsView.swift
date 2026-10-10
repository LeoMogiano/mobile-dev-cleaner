import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack(alignment: .center, spacing: 14) {
                    MDCAppIcon(size: 56)

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
                SettingsLinkRow(
                    icon: Image(systemName: "star.fill"),
                    iconColor: .white,
                    background: AnyShapeStyle(LinearGradient(
                        colors: [Color(hex: 0x4aa3ff), Color(hex: 0x007aff)], startPoint: .top, endPoint: .bottom)),
                    title: "Dale una estrella en GitHub",
                    detail: "Ayuda a que más devs la encuentren",
                    url: "https://github.com/LeoMogiano/mobile-dev-cleaner"
                )

                SettingsLinkRow(
                    icon: Image(systemName: "exclamationmark.triangle"),
                    iconColor: Color.mdcText2,
                    background: AnyShapeStyle(Color.mdcFill),
                    title: "Reportar un problema",
                    detail: "GitHub Issues",
                    url: "https://github.com/LeoMogiano/mobile-dev-cleaner/issues"
                )
            }

            Section {
                Text("Android es una marca de Google LLC. El robot de Android es una reproducción o modificación de una obra creada y compartida por Google, usada según los términos descritos en la licencia Creative Commons Attribution 3.0.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Color.mdcText3)
            }
        }
        .formStyle(.grouped)
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
    }
}
