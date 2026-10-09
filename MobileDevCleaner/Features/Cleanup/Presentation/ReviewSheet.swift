import SwiftUI

/// Minimal review step until the full flow (blocked apps, cost confirmation, progress) lands.
struct ReviewSheet: View {
    @Environment(ScanStore.self) private var scanStore
    @Environment(SelectionStore.self) private var selection
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Revisar y limpiar")
                .font(.system(size: 15, weight: .semibold))
            Text("Vas a liberar \(ByteFormatter.string(selection.selectedBytes(in: scanStore.reports)))")
                .foregroundStyle(Color.mdcText2)
            HStack {
                Spacer()
                Button("Cancelar") { dismiss() }
                    .buttonStyle(MDCSecondaryButtonStyle(height: 28))
                    .keyboardShortcut(.cancelAction)
                Button("Limpiar") {}
                    .buttonStyle(MDCPrimaryButtonStyle())
                    .disabled(true)
            }
        }
        .font(.system(size: 13))
        .padding(20)
        .frame(width: 520)
    }
}
