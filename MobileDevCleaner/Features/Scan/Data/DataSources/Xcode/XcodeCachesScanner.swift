import Foundation

struct XcodeCachesScanner: CategoryScanner {
    let category: CategoryID = .caches

    private let caches: [(path: URL, name: String)] = []

    func scan(in context: ScanContext) async -> CategoryReport {
        let specs = [
            (context.paths.caches.appending(path: "com.apple.dt.Xcode"), L10n.string("Caché de Xcode")),
            (context.paths.coreSimulatorCaches, L10n.string("Cachés del simulador")),
            (context.paths.logs.appending(path: "CoreSimulator"), L10n.string("Logs del simulador")),
            (context.paths.caches.appending(path: "org.swift.swiftpm"), L10n.string("Caché de Swift Package Manager")),
            (context.paths.caches.appending(path: "com.apple.amp.itmstransporter"), L10n.string("Caché de Transporter")),
            (context.paths.developer.appending(path: "XCPGDevices"), L10n.string("Dispositivos de Playgrounds")),
            (context.paths.xcode.appending(path: "Packages"), L10n.string("Paquetes descargados por Xcode")),
            (context.paths.xcode.appending(path: "DeveloperDiskImages"), L10n.string("Imágenes de disco de desarrollo")),
            (context.paths.xcode.appending(path: "DVTDownloads"), L10n.string("Descargas de Xcode")),
            (context.paths.xcode.appending(path: "UserData/IDEEditorInteractivityHistory"), L10n.string("Historial del editor")),
            (context.paths.xcode.appending(path: "UserData/IB Support"), L10n.string("Soporte de Interface Builder")),
            (context.paths.developer.appending(path: "Shared/Documentation/DocSets"), L10n.string("DocSets antiguos")),
        ]

        let candidateSpecs = specs.map { url, name in
            CandidateSpec(url: url, name: name, risk: .regenerates)
        }

        let candidates = await context.candidates(for: candidateSpecs, category: category).sortedForDisplay()
        return CategoryReport(id: category, candidates: candidates)
    }
}
