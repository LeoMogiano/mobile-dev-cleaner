import Foundation

struct PreviewsScanner: CategoryScanner {
    let category: CategoryID = .previews

    func scan(in context: ScanContext) async -> CategoryReport {
        let previewsPath = context.paths.previews
        let execution = ExecutionStrategy.command(
            executable: "/usr/bin/xcrun",
            arguments: ["simctl", "--set", "previews", "delete", "all"]
        )

        let spec = CandidateSpec(
            url: previewsPath,
            name: L10n.string("Previews de SwiftUI"),
            risk: .regenerates,
            execution: execution
        )

        let candidates = await context.candidates(for: [spec], category: category).sortedForDisplay()
        return CategoryReport(id: category, candidates: candidates)
    }
}
