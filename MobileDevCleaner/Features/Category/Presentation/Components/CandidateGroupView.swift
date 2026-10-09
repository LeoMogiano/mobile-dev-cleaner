import SwiftUI

struct CandidateGroupView: View {
    let group: CandidateGroupModel
    let onToggle: (String) -> Void
    let onInspect: (String) -> Void
    let onShowInFinder: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title = group.title {
                header(title)
            }
            LazyVStack(spacing: 0) {
                ForEach(group.rows) { row in
                    if row.id != group.rows.first?.id {
                        Rectangle().fill(Color.mdcLine).frame(height: 0.5)
                    }
                    CandidateRow(
                        row: row,
                        onToggle: { onToggle(row.id) },
                        onInspect: { onInspect(row.id) },
                        onShowInFinder: { onShowInFinder(row.id) }
                    )
                    .equatable()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .mdcCard(radius: 10)
        }
    }

    private func header(_ title: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.mdcText2)
            if let tag = group.tag {
                Text(tag)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Color.mdcText2)
                    .padding(.horizontal, 7)
                    .frame(height: 18)
                    .background(Color.mdcFill, in: Capsule())
            }
            Spacer()
            Text(group.sizeText)
                .font(.system(size: 11))
                .foregroundStyle(Color.mdcText3)
                .monospacedDigit()
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    CandidateGroupView(
        group: CandidateGroupModel(
            id: "orphanProjects", title: "Proyectos que ya no existen", sizeText: "1,2 GB",
            tag: "Huérfano: seguro de borrar",
            rows: [.preview(name: "old-prototype"), .preview(name: "demo", selected: true)]
        ),
        onToggle: { _ in }, onInspect: { _ in }, onShowInFinder: { _ in }
    )
    .frame(width: 600)
    .padding()
}
