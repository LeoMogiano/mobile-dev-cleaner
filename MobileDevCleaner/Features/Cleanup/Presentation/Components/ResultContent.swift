import SwiftUI

struct ResultContent: View {
    let freedText: String
    let countText: String
    let wasCancelled: Bool
    let showsTrashNote: Bool
    let failureHeader: String
    let failures: [ResultFailureRow]
    let isFailuresExpanded: Bool
    let onToggleFailures: () -> Void
    let onShowInFinder: (String) -> Void
    let onShowHistory: () -> Void
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                check
                if wasCancelled {
                    Text("Limpieza cancelada")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.mdcText2)
                        .padding(.top, 14)
                }
                Text("Liberaste \(freedText)")
                    .font(.mont(30, weight: .bold))
                    .tracking(-1.05)
                    .padding(.top, 14)
                    .accessibilityAddTraits(.isHeader)
                Text(countText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mdcText3)
                    .padding(.top, 2)
                growthNote
                if showsTrashNote {
                    Label("Está en la Papelera. El espacio se libera al vaciarla.", systemImage: "trash")
                        .labelStyle(SpacedLabelStyle(spacing: 6))
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.mdcText2)
                        .padding(.top, 10)
                }
            }
            .padding(EdgeInsets(top: 30, leading: 30, bottom: 8, trailing: 30))

            if !failures.isEmpty {
                ResultFailureList(
                    header: failureHeader,
                    failures: failures,
                    isExpanded: isFailuresExpanded,
                    onToggle: onToggleFailures,
                    onShowInFinder: onShowInFinder
                )
                .padding(.top, 10)
                .padding(.horizontal, 26)
            }

            HStack(spacing: 8) {
                Spacer()
                Button("Ver historial", action: onShowHistory)
                    .buttonStyle(MDCSecondaryButtonStyle(height: 28, horizontalPadding: 14, fontSize: 13, weight: .regular))
                Button("Listo", action: onDone)
                    .buttonStyle(MDCPrimaryButtonStyle(horizontalPadding: 22))
                    .keyboardShortcut(.defaultAction)
            }
            .padding(EdgeInsets(top: 18, leading: 24, bottom: 20, trailing: 24))
        }
        .onAppear {
            hasAppeared = true
            MDCAnnounce.post(L10n.string("Liberaste \(freedText)"))
        }
    }

    private var check: some View {
        Image(systemName: wasCancelled ? "minus" : "checkmark")
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 64, height: 64)
            .background(wasCancelled ? Color.mdcCost : Color.mdcRegen, in: Circle())
            .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.4)
            .opacity(hasAppeared || reduceMotion ? 1 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.55), value: hasAppeared)
            .accessibilityHidden(true)
    }

    private var growthNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14))
                .foregroundStyle(Color.mdcRegenInk)
                .padding(.top, 1)
                .accessibilityHidden(true)
            Text("Parte de esto volverá a crecer mientras desarrollas. Es normal: así funcionan Xcode y Gradle. Te recomendamos revisar cada 2–4 semanas.")
                .font(.system(size: 12.5))
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.mdcRegenBg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.top, 16)
    }
}
