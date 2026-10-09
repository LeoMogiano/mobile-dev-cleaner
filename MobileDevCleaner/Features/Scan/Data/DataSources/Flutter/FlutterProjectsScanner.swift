import Foundation

struct FlutterProjectsScanner: CategoryScanner {
    let category: CategoryID = .fprojects

    func scan(in context: ScanContext) async -> CategoryReport {
        var report = CategoryReport(id: category)
        let projects = await context.flutter.projects()
        let counts = Dictionary(grouping: projects, by: \.name).mapValues(\.count)

        var specs: [CandidateSpec] = []
        for project in projects {
            var label = project.name
            if counts[project.name, default: 0] > 1 {
                label = "\(project.root.deletingLastPathComponent().lastPathComponent)/\(project.name)"
            }
            for folder in ["build", ".dart_tool"] {
                let url = project.root.appending(path: folder, directoryHint: .isDirectory)
                guard context.isDirectory(url) else { continue }
                specs.append(CandidateSpec(url: url, name: "\(label) · \(folder)", risk: .regenerates))
            }
        }
        report.candidates = await context.candidates(for: specs, category: category).sortedForDisplay()
        return report
    }
}
