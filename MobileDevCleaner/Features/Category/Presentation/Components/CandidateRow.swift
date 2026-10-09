import SwiftUI

struct CandidateRow: View, Equatable {
    let row: CandidateRowModel
    let onToggle: () -> Void
    let onInspect: () -> Void
    let onShowInFinder: () -> Void

    @State private var isHovering = false

    static func == (lhs: CandidateRow, rhs: CandidateRow) -> Bool {
        lhs.row == rhs.row
    }

    var body: some View {
        HStack(spacing: 10) {
            MDCCheckbox(isOn: row.isSelected, action: onToggle)
                .help("Marcar (␣)")
            Text(row.name)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let path = row.path {
                Text(path)
                    .font(.mdcMono(11))
                    .foregroundStyle(Color.mdcText3)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(-1)
            }
            if row.showsBadge {
                MDCRiskBadge(kind: MDCBadgeKind(row.risk), compact: true)
            }
            MDCSizeBar(fraction: max(0.03, row.fraction), tint: row.risk == .regenerates ? .mdcRegen : .mdcCost)
            Text(row.sizeText)
                .fontWeight(.medium)
                .monospacedDigit()
                .lineLimit(1)
                .frame(width: 58, alignment: .trailing)
            Button(action: onShowInFinder) {
                Image(systemName: "arrow.up.forward.circle")
                    .font(.system(size: 14))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.mdcAccent)
            .opacity(row.isInspected || isHovering ? 1 : 0.4)
            .help("Mostrar en Finder")
            .accessibilityLabel("Mostrar en Finder")
        }
        .font(.system(size: 13))
        .foregroundStyle(Color.mdcText1)
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .frame(height: 34)
        // Inset pill instead of clipping the whole list: clipping a long stack costs every scroll frame.
        .background(background, in: RoundedRectangle(cornerRadius: 7, style: .continuous).inset(by: 3))
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("Ver detalles", action: onInspect)
            Button("Mostrar en Finder", action: onShowInFinder)
        }
        .opacity(row.isExcluded ? 0.5 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(row.accessibilityLabel)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(valueLabel)
        .accessibilityAction(named: "Marcar", onToggle)
        .accessibilityAction(named: "Ver detalles", onInspect)
        .accessibilityAction(named: "Mostrar en Finder", onShowInFinder)
    }

    private var valueLabel: String {
        if row.isExcluded { return L10n.string("Excluido") }
        return row.isSelected ? L10n.string("Marcado") : L10n.string("Sin marcar")
    }

    private var background: Color {
        if row.isInspected { return .mdcAccentBg }
        return isHovering ? .mdcHover : .clear
    }
}

#Preview {
    VStack(spacing: 0) {
        CandidateRow(row: .preview(name: "MyBankApp", selected: true), onToggle: {}, onInspect: {}, onShowInFinder: {})
        CandidateRow(row: .preview(name: "old-prototype", inspected: true), onToggle: {}, onInspect: {}, onShowInFinder: {})
        CandidateRow(row: .preview(name: "EGXOne", excluded: true), onToggle: {}, onInspect: {}, onShowInFinder: {})
    }
    .frame(width: 600)
    .padding()
}

extension CandidateRowModel {
    static func preview(
        name: String, selected: Bool = false, excluded: Bool = false, inspected: Bool = false
    ) -> CandidateRowModel {
        CandidateRowModel(
            id: name, name: name, path: nil, sizeText: "2,4 GB", fraction: 0.6, risk: .regenerates,
            showsBadge: false, isSelected: selected, isExcluded: excluded, isInspected: inspected,
            accessibilityLabel: name
        )
    }
}
