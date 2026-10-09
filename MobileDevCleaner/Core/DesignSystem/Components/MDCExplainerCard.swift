import SwiftUI

struct MDCExplainerCard: View {
    let whatIsIt: String
    let ifDeleted: String
    let comesBack: String
    @Binding var isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(reduceMotion ? nil : .linear(duration: 0.2)) {
                isExpanded.toggle()
            }}) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.mdcAccent)

                    Text("¿Qué es y qué pasa si lo borro?")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(.mdcText1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.mdcText3)
                }
                .frame(height: 36)
                .padding(.horizontal, 14)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(spacing: 0) {
                    HStack(spacing: 1) {
                        ExplainerColumn(
                            title: "¿Qué es?",
                            content: whatIsIt
                        )

                        Divider()
                            .frame(width: 1)
                            .background(Color.mdcLine)

                        ExplainerColumn(
                            title: "¿Qué pasa si lo borro?",
                            content: ifDeleted
                        )

                        Divider()
                            .frame(width: 1)
                            .background(Color.mdcLine)

                        ExplainerColumn(
                            title: "¿Vuelve a aparecer?",
                            content: comesBack,
                            hasIcon: true
                        )
                    }
                    .mdcInner()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .mdcCard(radius: 12)
    }
}

private struct ExplainerColumn: View {
    let title: String
    let content: String
    var hasIcon: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.mdcText2)

                if hasIcon {
                    Image(systemName: "arrow.2.circlepath")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.mdcText2)
                }
            }

            Text(content)
                .font(.system(size: 12.5, weight: .regular))
                .foregroundColor(.mdcText1)
                .lineLimit(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
    }
}

#Preview {
    @Previewable @State var expanded = false

    VStack {
        MDCExplainerCard(
            whatIsIt: "Son archivos temporales generados durante las compilaciones.",
            ifDeleted: "Se regenerarán automáticamente en la próxima compilación.",
            comesBack: "Sí, se vuelven a generar.",
            isExpanded: $expanded
        )
        .padding()

        Spacer()
    }
}
