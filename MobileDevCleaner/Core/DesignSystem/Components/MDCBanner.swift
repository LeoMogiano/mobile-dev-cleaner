import SwiftUI

struct MDCBanner: View {
    let message: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let onAction: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
                .font(.system(size: 16))
                .foregroundColor(.mdcCostInk)

            Text(message)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(.mdcText1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(actionTitle) {
                onAction()
            }
            .buttonStyle(MDCSecondaryButtonStyle())

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.mdcText2)
            }
            .frame(width: 22, height: 22)
            .buttonStyle(PlainButtonStyle())
            .help("Descartar")
            .accessibilityLabel("Descartar")
        }
        .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 12))
        .background(Color.mdcCostBg)
        .cornerRadius(10, antialiased: true)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    MDCBanner(
        message: "Algunas carpetas no se pudieron medir.",
        actionTitle: "Dar acceso",
        onAction: {},
        onDismiss: {}
    )
    .padding()
}
