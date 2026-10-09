import Foundation

struct FlutterSdkCacheScanner: CategoryScanner {
    let category: CategoryID = .fsdk
    let extraRoots: [URL]

    init(extraRoots: [URL] = FlutterSdkCacheScanner.systemRoots) {
        self.extraRoots = extraRoots
    }

    static var systemRoots: [URL] {
        var roots = ["/opt/homebrew/share/flutter", "/usr/local/share/flutter"].map { URL(filePath: $0, directoryHint: .isDirectory) }
        let caskroom = URL(filePath: "/opt/homebrew/Caskroom/flutter", directoryHint: .isDirectory)
        let versions = (try? FileManager.default.contentsOfDirectory(atPath: caskroom.path)) ?? []
        roots += versions.map { caskroom.appending(path: "\($0)/flutter", directoryHint: .isDirectory) }
        return roots
    }

    func scan(in context: ScanContext) async -> CategoryReport {
        var report = CategoryReport(id: category)
        let home = context.paths.home
        var roots = await context.flutter.projects().compactMap(\.flutterRoot)
        roots += ["flutter", "development/flutter", "dev/flutter", "sdk/flutter"]
            .map { home.appending(path: $0, directoryHint: .isDirectory) }
        roots += extraRoots

        let fvmRoot = context.paths.fvmVersions.resolvingSymlinksInPath().path + "/"
        var seen = Set<String>()
        var specs: [CandidateSpec] = []
        for candidate in roots {
            let root = candidate.resolvingSymlinksInPath()
            guard seen.insert(root.path).inserted,
                  !(root.path + "/").hasPrefix(fvmRoot),
                  context.exists(root.appending(path: "bin/flutter")) else { continue }
            let cache = root.appending(path: "bin/cache", directoryHint: .isDirectory)
            guard context.isDirectory(cache) else { continue }
            specs.append(CandidateSpec(
                url: cache,
                name: "Flutter \(Self.version(of: root, context: context) ?? Self.abbreviated(root, home: home))",
                risk: .hasCost,
                cost: { size in
                    let sizeText = "~\(ByteFormatter.string(size, locale: AppLanguage.current.locale))"
                    return L10n.string("Se descargará de nuevo (\(sizeText)) al usar flutter.")
                }))
        }
        report.candidates = await context.candidates(for: specs, category: category).sortedForDisplay()
        return report
    }

    private static func version(of root: URL, context: ScanContext) -> String? {
        if let text = context.readText(root.appending(path: "version"))?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            return text
        }
        let json = root.appending(path: "bin/cache/flutter.version.json")
        guard let data = try? Data(contentsOf: json),
              let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        return object["frameworkVersion"] as? String
    }

    private static func abbreviated(_ url: URL, home: URL) -> String {
        let homePath = home.resolvingSymlinksInPath().path
        return url.path.hasPrefix(homePath) ? "~" + url.path.dropFirst(homePath.count) : url.path
    }
}
