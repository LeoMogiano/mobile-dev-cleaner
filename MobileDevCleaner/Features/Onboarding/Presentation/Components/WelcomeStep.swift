import SwiftUI

struct WelcomeStep: View {
    var body: some View {
        HStack(spacing: 36) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
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
                        .frame(width: 40, height: 40)
                        .cornerRadius(11)

                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.white)
                    }

                    Text("Mobile Dev Cleaner")
                        .font(.mont(15, weight: .bold))
                        .tracking(-0.30)
                }

                Text("Recupera espacio sin romper nada.")
                    .font(.mont(36, weight: .bold))
                    .tracking(-1.44)
                    .lineLimit(3)
                    .padding(.top, 26)

                Text("Encuentra lo que Xcode y Android Studio dejan atrás y te explica qué es antes de borrarlo.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mdcText2)
                    .lineLimit(3)
                    .padding(.top, 14)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("En la Mac de un dev mobile")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.mdcText3)

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("37,7")
                        .font(.mont(34, weight: .bold))
                        .tracking(-1.53)
                    Text("GB")
                        .font(.mont(15, weight: .bold))
                }
                .padding(.top, 2)

                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.mdcRegen)
                        .frame(maxWidth: .infinity)
                    Rectangle()
                        .fill(Color.mdcCost)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 8)
                .cornerRadius(4)
                .padding(.top, 12)

                VStack(spacing: 0) {
                    row(icon: "hammer", color: Color.mdcXcode, title: "Builds de Xcode", status: "regen", value: "6,1 GB")
                    row(icon: "shippingbox", color: Color.mdcAndroid, title: "Cachés de Gradle", status: "regen", value: "7,4 GB")
                    row(icon: "iphone", color: Color.mdcXcode, title: "Simuladores iOS", status: "cost", value: "3,8 GB")
                    row(icon: "key", color: Color.mdcText3, title: "Keystores y certificados", status: "lock", value: "—", isDisabled: true)
                }
                .padding(.top, 12)
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 10, trailing: 16))
            .frame(width: 290)
            .mdcCard(radius: 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(icon: String, color: Color, title: String, status: String, value: String, isDisabled: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 12))
            Spacer()
            Image(systemName: statusIcon(status))
                .font(.system(size: 12))
                .foregroundStyle(statusColor(status))
            Text(value)
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundStyle(isDisabled ? Color.mdcText3 : Color.mdcText2)
                .fixedSize()
                .frame(minWidth: 44, alignment: .trailing)
        }
        .frame(height: 32)
        .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Color.mdcLine), alignment: .top)
        .foregroundStyle(isDisabled ? Color.mdcText3 : Color.mdcText1)
    }

    private func statusIcon(_ status: String) -> String {
        switch status {
        case "regen": "arrow.triangle.2.circlepath"
        case "cost": "clock.arrow.circlepath"
        case "lock": "lock.fill"
        default: ""
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "regen": Color.mdcRegenInk
        case "cost": Color.mdcCostInk
        case "lock": Color.mdcText2
        default: Color.mdcText2
        }
    }
}

#Preview {
    WelcomeStep()
}
