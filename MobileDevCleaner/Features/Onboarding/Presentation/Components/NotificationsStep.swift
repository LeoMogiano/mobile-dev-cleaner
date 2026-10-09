import SwiftUI

struct NotificationsStep: View {
    let isAllowed: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .center) {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: 0xff6b5f), location: 0),
                        .init(color: Color(hex: 0xff3b30), location: 1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 76, height: 76)
                .cornerRadius(20)

                Image(systemName: "bell.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.white)
            }

            Text("¿Te avisamos cuando termine la limpieza?")
                .font(.mont(28, weight: .bold))
                .tracking(-0.84)
                .lineLimit(2)
                .padding(.top, 24)

            Text("Así puedes seguir trabajando mientras limpiamos. Una sola notificación al terminar, con lo que liberaste. Nada más.")
                .font(.system(size: 13.5))
                .foregroundStyle(Color.mdcText2)
                .lineLimit(3)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 10) {
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
                        .frame(width: 30, height: 30)
                        .cornerRadius(8)

                        Image(systemName: "trash.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Limpieza completada")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Liberaste 18,2 GB. Parte volverá a crecer al compilar.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Color.mdcText2)
                    }

                    Spacer()
                    Text("ahora")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color.mdcText3)
                }
                .padding(10)
                .mdcCard(radius: 14)
            }
            .frame(width: 340)
            .padding(.top, 22)

            if isAllowed {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.mdcRegenInk)
                    Text("Notificaciones activadas")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color.mdcRegenInk)
                }
                .padding(.top, 14)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NotificationsStep(isAllowed: false)
}
