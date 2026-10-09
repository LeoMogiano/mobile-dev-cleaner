import Foundation

struct TestResiduesScanner: CategoryScanner {
    let category: CategoryID = .tests

    func scan(in context: ScanContext) async -> CategoryReport {
        let testDevicesPath = context.paths.developer.appending(path: "XCTestDevices")
        let spec = CandidateSpec(
            url: testDevicesPath,
            name: L10n.string("Dispositivos de test"),
            risk: .regenerates
        )

        let candidates = await context.candidates(for: [spec], category: category).sortedForDisplay()
        return CategoryReport(id: category, candidates: candidates)
    }
}
