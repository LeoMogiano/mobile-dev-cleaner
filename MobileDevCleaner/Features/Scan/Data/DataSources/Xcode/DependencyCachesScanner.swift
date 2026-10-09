import Foundation

struct DependencyCachesScanner: CategoryScanner {
    let category: CategoryID = .pods

    func scan(in context: ScanContext) async -> CategoryReport {
        var specs: [CandidateSpec] = []

        specs.append(CandidateSpec(
            url: context.paths.caches.appending(path: "CocoaPods"),
            name: L10n.string("Caché de CocoaPods"),
            risk: .regenerates
        ))

        specs.append(CandidateSpec(
            url: context.paths.caches.appending(path: "org.carthage.CarthageKit"),
            name: L10n.string("Caché de Carthage"),
            risk: .regenerates
        ))

        specs.append(CandidateSpec(
            url: context.paths.home.appending(path: ".fastlane"),
            name: L10n.string("Caché de fastlane"),
            risk: .regenerates
        ))

        specs.append(CandidateSpec(
            url: context.paths.cocoapodsRepos,
            name: L10n.string("Repositorios de specs de CocoaPods"),
            risk: .hasCost,
            cost: { size in
                let formatted = ByteFormatter.string(size, locale: AppLanguage.current.locale)
                return L10n.string("pod install volverá a descargar los specs (~\(formatted)).")
            }
        ))

        let candidates = await context.candidates(for: specs, category: category).sortedForDisplay()
        return CategoryReport(id: category, candidates: candidates)
    }
}
