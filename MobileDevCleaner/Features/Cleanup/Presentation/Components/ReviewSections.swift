import SwiftUI

/// Scrollable middle of the review: "Se regenera solo", "Tiene costo" and commands.
struct ReviewSections: View {
    let regenerateHeader: String?
    let regenerateRows: [ReviewGroupRow]
    let costHeader: String?
    let costRows: [ReviewCostRow]
    let commands: [String]?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let regenerateHeader {
                section(title: "Se regenera solo", symbol: "arrow.triangle.2.circlepath", tint: .mdcRegenInk, detail: regenerateHeader) {
                    ForEach(regenerateRows) { row in
                        HStack(spacing: 9) {
                            Image(systemName: row.symbol)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.mdcText2)
                                .frame(width: 16)
                            Text(row.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.countText)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.mdcText3)
                            Text(row.sizeText)
                                .monospacedDigit()
                                .frame(width: 62, alignment: .trailing)
                        }
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .rowSeparator(isFirst: row.id == regenerateRows.first?.id)
                    }
                }
            }
            if let costHeader {
                section(title: "Tiene costo", symbol: "clock.arrow.circlepath", tint: .mdcCostInk, detail: costHeader) {
                    ForEach(costRows) { row in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 9) {
                                Text(row.name)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(row.categoryName)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.mdcText3)
                                Text(row.sizeText)
                                    .monospacedDigit()
                                    .frame(width: 62, alignment: .trailing)
                            }
                            .lineLimit(1)
                            if !row.note.isEmpty {
                                Text(row.note)
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(Color.mdcText2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .rowSeparator(isFirst: row.id == costRows.first?.id)
                    }
                }
            }
            if let commands {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Comandos que se ejecutarán")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.mdcText2)
                    ViewThatFits(in: .vertical) {
                        commandList(commands)
                        ScrollView([.horizontal, .vertical]) { commandList(commands) }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 110, alignment: .topLeading)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(Color.mdcFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .font(.system(size: 12.5))
        .padding(EdgeInsets(top: 4, leading: 24, bottom: 8, trailing: 24))
    }

    private func section<Rows: View>(
        title: LocalizedStringKey, symbol: String, tint: Color, detail: String, @ViewBuilder rows: () -> Rows
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                Text(title).fontWeight(.semibold)
                Text("· \(detail)").foregroundStyle(Color.mdcText2)
            }
            .font(.system(size: 12))
            .foregroundStyle(tint)
            VStack(spacing: 0, content: rows)
                .mdcInner(radius: 10)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.mdcLine, lineWidth: 0.5))
        }
    }

    private func commandList(_ commands: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(commands.enumerated()), id: \.offset) { _, command in
                Text("$ \(command)")
            }
        }
        .font(.mdcMono(10.5))
        .lineSpacing(6)
        .foregroundStyle(Color.mdcText2)
        .fixedSize()
        .textSelection(.enabled)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
    }
}

private extension View {
    func rowSeparator(isFirst: Bool) -> some View {
        overlay(alignment: .top) {
            if !isFirst { Rectangle().fill(Color.mdcLine).frame(height: 0.5) }
        }
    }
}
