import SwiftUI

/// Category variant of the access banner: bold title, explanation, no dismiss.
struct CategoryAccessBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 16))
                .foregroundStyle(Color.mdcCostInk)
            (Text("Algunas carpetas no se pudieron medir. ").fontWeight(.semibold)
                + Text("Esta carpeta es del sistema y necesita Acceso total al disco.").foregroundStyle(Color.mdcText2))
                .font(.system(size: 12.5))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Dar acceso") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(MDCSecondaryButtonStyle())
        }
        .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 12))
        .background(Color.mdcCostBg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
