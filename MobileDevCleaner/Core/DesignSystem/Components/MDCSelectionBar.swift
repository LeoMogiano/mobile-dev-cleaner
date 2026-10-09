import SwiftUI

struct MDCSelectionBar: View {
    let count: Int
    let bytes: Int64
    let onDeselect: () -> Void
    let onReview: () -> Void

    @Environment(\.mdcMaterial) private var material

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: material.usesGlass ? 12 : 6, style: .continuous)
    }

    private var sheet: Color {
        material.usesGlass ? Self.glassSheet : Self.classicSheet
    }

    private static let glassSheet = Color(light: (0xFAFAFD, 0.9), dark: (0x2E2E34, 0.92))
    private static let classicSheet = Color(light: 0xFFFFFF, dark: 0x2C2C2E)

    private var countLabel: String {
        let plural = count == 1 ? "" : "s"
        return "\(count) seleccionado\(plural)"
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(countLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.mdcText1)

            Text("· \(ByteFormatter.string(bytes, locale: AppLanguage.current.locale))")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.mdcText2)
                .monospacedDigit()

            Button("Deseleccionar") {
                onDeselect()
            }
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.mdcAccent)
            .frame(height: 28)
            .padding(.horizontal, 10)
            .buttonStyle(PlainButtonStyle())

            Button(action: onReview) {
                Text("Revisar y limpiar")
            }
            .buttonStyle(MDCPrimaryButtonStyle(height: 30, horizontalPadding: 16))
            .keyboardShortcut(.delete, modifiers: [])
            .help("Revisar y limpiar (⌫)")
        }
        .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 6))
        .background(sheet, in: shape)
        .overlay(shape.strokeBorder(Color.mdcLine2, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.18), radius: 15, x: 0, y: 10)
        .transition(.opacity.animation(.easeOut(duration: 0.18)))
    }
}

#Preview {
    ZStack {
        Rectangle()
            .fill(Color.gray.opacity(0.1))

        VStack(spacing: 20) {
            Spacer()

            MDCSelectionBar(
                count: 3,
                bytes: 5_000_000_000,
                onDeselect: {},
                onReview: {}
            )
            .padding(.horizontal)

            Spacer()
        }
    }
}
