import Foundation

struct PubCacheScanner: CategoryScanner {
    let category: CategoryID = .pubcache

    func scan(in context: ScanContext) async -> CategoryReport {
        var report = CategoryReport(id: category)
        let spec = CandidateSpec(
            url: context.paths.pubCache,
            name: L10n.string("Caché de pub"),
            risk: .hasCost,
            cost: { size in
                let sizeText = "~\(ByteFormatter.string(size, locale: AppLanguage.current.locale))"
                return L10n.string("Se descargarán de nuevo los paquetes (\(sizeText)) al hacer pub get.")
            })
        report.candidates = await context.candidates(for: [spec], category: category)
        return report
    }
}
