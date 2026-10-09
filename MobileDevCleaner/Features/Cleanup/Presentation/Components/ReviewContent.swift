import SwiftUI

struct ReviewContent: View {
    let totalText: String
    let countText: String
    let regenerateHeader: String?
    let regenerateRows: [ReviewGroupRow]
    let costHeader: String?
    let costRows: [ReviewCostRow]
    let commands: [String]?
    let movesToTrash: Bool
    let needsUnderstanding: Bool
    let understands: Bool
    let primaryTitle: String
    let canClean: Bool
    let onToggleTrash: () -> Void
    let onToggleUnderstands: () -> Void
    let onCancel: () -> Void
    let onClean: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            // Hug short reviews; scroll only when the list outgrows the sheet.
            ViewThatFits(in: .vertical) {
                sections
                ScrollView { sections }
            }
            footer
        }
    }

    private var sections: ReviewSections {
        ReviewSections(
            regenerateHeader: regenerateHeader, regenerateRows: regenerateRows,
            costHeader: costHeader, costRows: costRows, commands: commands)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "trash")
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0x3A / 255, green: 0xA0 / 255, blue: 1), location: 0),
                            .init(color: Color(red: 0x5B / 255, green: 0x6C / 255, blue: 1), location: 0.55),
                            .init(color: Color(red: 0xA3 / 255, green: 0x5B / 255, blue: 1), location: 1),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("Vas a liberar \(totalText)")
                    .font(.system(size: 17, weight: .bold))
                    .tracking(-0.17)
                Text(countText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mdcText2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 22, leading: 24, bottom: 12, trailing: 24))
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            checkRow(isOn: movesToTrash, action: onToggleTrash) {
                Text("Mover a la Papelera ") + Text("(puedes recuperarlos)").foregroundStyle(Color.mdcText3)
            }
            if needsUnderstanding {
                checkRow(isOn: understands, action: onToggleUnderstands) {
                    Text("Entiendo que algunos se volverán a descargar o perderán datos")
                }
            }
            HStack(spacing: 8) {
                Spacer()
                Button("Cancelar", action: onCancel)
                    .buttonStyle(MDCSecondaryButtonStyle(height: 28, horizontalPadding: 14, fontSize: 13, weight: .regular))
                    .keyboardShortcut(.cancelAction)
                Button(primaryTitle, action: onClean)
                    .buttonStyle(MDCPrimaryButtonStyle(horizontalPadding: 18))
                    .disabled(!canClean)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 6)
        }
        .padding(EdgeInsets(top: 10, leading: 24, bottom: 18, trailing: 24))
        .overlay(alignment: .top) { Rectangle().fill(Color.mdcLine).frame(height: 0.5) }
    }

    private func checkRow(isOn: Bool, action: @escaping () -> Void, @ViewBuilder label: () -> Text) -> some View {
        HStack(spacing: 8) {
            MDCCheckbox(isOn: isOn, action: action)
            label().font(.system(size: 12.5))
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}
