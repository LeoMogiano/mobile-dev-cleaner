import SwiftUI

/// The four numbered steps and the waiting/granted line (HTML lines 559-569).
struct FullDiskAccessGuide: View {
    let status: FullDiskAccessViewModel.Status

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                row(1, icon: "gearshape", text: Text("Abre ") + bold("Ajustes del Sistema"))
                row(2, icon: "lock", text: Text("Ve a ") + bold("Privacidad y seguridad"))
                row(3, icon: "internaldrive", text: Text("Entra en ") + bold("Acceso total al disco"))
                lastRow
            }
            .font(.system(size: 12.5))
            .frame(width: 400)
            .mdcCard(radius: 12)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            statusLine
                .frame(height: 22)
                .padding(.top, 12)
        }
    }

    private func bold(_ s: LocalizedStringKey) -> Text { Text(s).fontWeight(.semibold) }

    private func badge(_ n: Int) -> some View {
        Text("\(n)")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.mdcAccentInk)
            .frame(width: 20, height: 20)
            .background(Color.mdcAccentBg, in: Circle())
    }

    private func row(_ n: Int, icon: String, text: Text) -> some View {
        HStack(spacing: 10) {
            badge(n)
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(Color.mdcText2)
            text
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 36)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.mdcLine).frame(height: 0.5) }
    }

    private var lastRow: some View {
        HStack(spacing: 10) {
            badge(4)
            Image(systemName: "trash")
                .font(.system(size: 11))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(
                    LinearGradient(
                        colors: [Color(light: 0x3AA0FF, dark: 0x3AA0FF), Color(light: 0xA35BFF, dark: 0xA35BFF)],
                        startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            (Text("Activa ") + bold("Mobile Dev Cleaner")).frame(maxWidth: .infinity, alignment: .leading)
            toggle
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
    }

    private var toggle: some View {
        let on = status == .granted
        return Capsule()
            .fill(on ? Color.mdcRegen : Color.mdcLine2)
            .frame(width: 32, height: 18)
            .overlay(alignment: .leading) {
                Circle().fill(.white).frame(width: 14, height: 14).offset(x: on ? 16 : 2)
            }
            .animation(.easeInOut(duration: 0.2), value: on)
    }

    @ViewBuilder private var statusLine: some View {
        switch status {
        case .waiting:
            HStack(spacing: 7) {
                ProgressView().controlSize(.small)
                Text("Esperando permiso…").foregroundStyle(Color.mdcText2)
            }
            .font(.system(size: 12))
        case .granted:
            HStack(spacing: 7) {
                Image(systemName: "checkmark").font(.system(size: 14, weight: .bold))
                Text("Acceso concedido").fontWeight(.semibold)
            }
            .font(.system(size: 12))
            .foregroundStyle(Color.mdcRegenInk)
        case .idle:
            Color.clear
        }
    }
}

struct FullDiskAccessIcon: View {
    var size: CGFloat = 64

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.mdcFill)
            .frame(width: size, height: size)
            .overlay { Image(systemName: "internaldrive").font(.system(size: 32)) }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.mdcAccent, in: Circle())
                    .overlay(Circle().strokeBorder(Color(nsColor: .windowBackgroundColor), lineWidth: 3))
                    .offset(x: 6, y: 6)
            }
    }
}
