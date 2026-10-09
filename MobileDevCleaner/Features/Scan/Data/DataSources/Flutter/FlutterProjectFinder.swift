import Foundation

/// A folder with a `pubspec.yaml`.
struct FlutterProject: Sendable, Hashable {
    let root: URL
    let name: String
    /// From `.dart_tool/package_config.json` (`flutterRoot`), when the project was built once.
    var flutterRoot: URL?
    /// Pinned FVM version from `.fvmrc` or `.fvm/fvm_config.json`.
    var fvmVersion: String?
}

protocol FlutterProjectLocating: Sendable {
    func projects() async -> [FlutterProject]
}

struct NoFlutterProjects: FlutterProjectLocating {
    func projects() async -> [FlutterProject] { [] }
}

/// Walks the home folder (depth ≤ 5) for `pubspec.yaml`. Scanners share one walk per scan.
actor FlutterProjectFinder: FlutterProjectLocating {
    let home: URL
    let maxDepth: Int
    let hasFullDiskAccess: @Sendable () async -> Bool

    init(home: URL, maxDepth: Int = 5, hasFullDiskAccess: @escaping @Sendable () async -> Bool) {
        self.home = home
        self.maxDepth = maxDepth
        self.hasFullDiskAccess = hasFullDiskAccess
    }

    private static let memoLifetime: TimeInterval = 10
    private var memo: (task: Task<[FlutterProject], Never>, startedAt: Date)?

    func projects() async -> [FlutterProject] {
        let task: Task<[FlutterProject], Never>
        if let memo, Date().timeIntervalSince(memo.startedAt) < Self.memoLifetime {
            task = memo.task
        } else {
            let skipProtected = await hasFullDiskAccess() == false
            let home = home, maxDepth = maxDepth
            task = Task.detached(priority: .utility) {
                let state = Signposts.scan.beginInterval("flutterProjects")
                defer { Signposts.scan.endInterval("flutterProjects", state) }
                return Self.walk(home: home, maxDepth: maxDepth, skipProtected: skipProtected)
            }
            memo = (task, Date())
        }
        return await withTaskCancellationHandler { await task.value } onCancel: { }
    }

    private static let skippedNames: Set<String> = [
        "Library", "node_modules", "build", ".dart_tool", "Pods", "fvm", ".pub-cache", ".Trash", "Applications",
    ]
    private static let protectedNames: Set<String> = ["Desktop", "Documents", "Downloads"]
    private static let mediaNames: Set<String> = ["Music", "Movies", "Pictures", "Public"]

    private nonisolated static func walk(home: URL, maxDepth: Int, skipProtected: Bool) -> [FlutterProject] {
        var found: [FlutterProject] = []
        func visit(_ path: String, depth: Int) {
            guard !Task.isCancelled, let dir = opendir(path) else { return }
            defer { closedir(dir) }
            var children: [String] = []
            var hasPubspec = false
            while let entry = readdir(dir) {
                let name = withUnsafePointer(to: &entry.pointee.d_name) {
                    $0.withMemoryRebound(to: CChar.self, capacity: Int(entry.pointee.d_namlen) + 1) { String(cString: $0) }
                }
                if entry.pointee.d_type == UInt8(DT_DIR) {
                    guard depth < maxDepth, !name.hasPrefix("."), !skippedNames.contains(name),
                          !(depth == 0 && mediaNames.contains(name)),
                          !(skipProtected && depth == 0 && protectedNames.contains(name)) else { continue }
                    children.append(name)
                } else if name == "pubspec.yaml", entry.pointee.d_type == UInt8(DT_REG) {
                    hasPubspec = true
                }
            }
            // A Flutter SDK ships dozens of internal packages; they are not the user's projects.
            if children.contains("bin"), children.contains("packages"), access(path + "/bin/flutter", F_OK) == 0 { return }
            if hasPubspec, depth > 0 { found.append(project(at: URL(filePath: path, directoryHint: .isDirectory))) }
            for child in children { visit(path + "/" + child, depth: depth + 1) }
        }
        visit(home.path, depth: 0)
        return found.sorted { $0.root.path < $1.root.path }
    }

    private nonisolated static func project(at root: URL) -> FlutterProject {
        var project = FlutterProject(root: root, name: root.lastPathComponent)
        let config = root.appending(path: ".dart_tool/package_config.json")
        if let json = json(config), let raw = json["flutterRoot"] as? String, let url = URL(string: raw), url.isFileURL {
            project.flutterRoot = url
        }
        let rc = json(root.appending(path: ".fvmrc"))
        let legacy = json(root.appending(path: ".fvm/fvm_config.json"))
        project.fvmVersion = (rc?["flutter"] as? String) ?? (rc?["flutterSdkVersion"] as? String)
            ?? (legacy?["flutterSdkVersion"] as? String)
        return project
    }

    private nonisolated static func json(_ url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
