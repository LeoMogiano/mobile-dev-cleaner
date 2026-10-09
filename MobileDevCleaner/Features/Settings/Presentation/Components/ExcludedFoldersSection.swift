import SwiftUI

struct ExcludedFoldersSection: View {
    let paths: [String]
    let onAdd: () -> Void
    let onRemove: (String) -> Void

    @State private var selected: String?

    var body: some View {
        VStack(spacing: 0) {
            if paths.isEmpty {
                VStack {
                    Text("No hay carpetas excluidas.")
                        .font(.system(size: 12))
                        .foregroundColor(.mdcText3)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            } else {
                ForEach(paths, id: \.self) { path in
                    VStack(alignment: .leading, spacing: 2) {
                        Button(action: { selected = path }) {
                            HStack(spacing: 10) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.mdcAccent)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(URL(filePath: path).lastPathComponent)
                                        .font(.system(size: 12.5, weight: .medium))
                                        .lineLimit(1)

                                    Text(abbreviatedPath(path))
                                        .font(.mdcMono(10.5))
                                        .foregroundColor(.mdcText3)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 7)
                            .padding(.horizontal, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(
                            selected == path
                                ? Color.mdcAccentBg
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )

                        if path != paths.last {
                            Rectangle()
                                .fill(Color.mdcLine)
                                .frame(height: 0.5)
                        }
                    }
                }
            }

            HStack(spacing: 0) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(width: 30, height: 24)
                .contentShape(Rectangle())
                .accessibilityLabel("Añadir carpeta")

                Rectangle()
                    .fill(Color.mdcLine)
                    .frame(width: 0.5)

                Button(action: {
                    if let sel = selected {
                        onRemove(sel)
                        selected = nil
                    } else if let last = paths.last {
                        onRemove(last)
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(width: 30, height: 24)
                .contentShape(Rectangle())
                .disabled(paths.isEmpty)
                .accessibilityLabel("Quitar carpeta")
            }
            .foregroundColor(.mdcText1)
            .buttonStyle(.borderless)
        }
    }

    private func abbreviatedPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + String(path.dropFirst(home.count))
        }
        return path
    }
}
