import SwiftUI

struct HistoryRow: View {
    let row: HistoryRowModel
    let onToggle: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: row.iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.mdcText3)

                Text(row.dateText)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 130, alignment: .leading)

                Text(row.countText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.mdcText2)

                Spacer()

                Text(row.freedText)
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
            }
            .frame(height: 42)
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .background(isHovered ? Color.mdcHover : .clear)
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggle)
            .onHover { isHovered = $0 }

            if row.isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(row.breakdown) { slice in
                        HStack(alignment: .center, spacing: 10) {
                            Text(slice.name)
                                .font(.system(size: 12, weight: .regular))
                                .frame(width: 180, alignment: .leading)
                                .lineLimit(1)

                            GeometryReader { proxy in
                                Capsule()
                                    .fill(Color.mdcAccent)
                                    .frame(width: proxy.size.width * slice.fraction)
                            }
                            .frame(height: 4)
                            .background(Color.mdcFill, in: Capsule())

                            Text(slice.valueText)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.mdcText2)
                                .monospacedDigit()
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                }
                .padding(EdgeInsets(top: 2, leading: 38, bottom: 14, trailing: 16))
            }
        }
    }
}
