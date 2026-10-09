import Foundation

struct AVDConfig: Sendable, Hashable {
    /// Folder name without `.avd`.
    let name: String
    let displayName: String
    let url: URL
    /// `image.sysdir.1`, e.g. "system-images/android-34/google_apis_playstore/arm64-v8a/".
    let systemImagePath: String?
    let apiLevel: Int?
    let deviceType: String?
}

enum AVDConfigReader {
    static func read(in context: ScanContext) -> [AVDConfig] {
        let root = context.paths.avd
        return context.contents(of: root)
            .filter { $0.pathExtension == "ini" }
            .map { config(forIni: $0, root: root, context: context) }
    }

    static func parseINI(_ text: String) -> [String: String] {
        var result: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("#"), let eq = trimmed.firstIndex(of: "=") else { continue }
            let key = trimmed[..<eq].trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { continue }
            result[key] = trimmed[trimmed.index(after: eq)...].trimmingCharacters(in: .whitespaces)
        }
        return result
    }

    static func androidVersion(api: Int) -> String? {
        [21: "5.0", 22: "5.1", 23: "6.0", 24: "7.0", 25: "7.1", 26: "8.0", 27: "8.1", 28: "9", 29: "10",
         30: "11", 31: "12", 32: "12L", 33: "13", 34: "14", 35: "15", 36: "16"][api]
    }

    /// "android-34" → 34
    static func apiLevel(from text: String) -> Int? {
        guard let range = text.range(of: "android-[0-9]+", options: .regularExpression) else { return nil }
        return Int(text[range].dropFirst("android-".count))
    }

    private static func config(forIni ini: URL, root: URL, context: ScanContext) -> AVDConfig {
        let name = ini.deletingPathExtension().lastPathComponent
        let fallback = root.appending(path: "\(name).avd", directoryHint: .isDirectory)
        let iniValues = parseINI(context.readText(ini) ?? "")
        let url = iniValues["path"].map { URL(filePath: $0, directoryHint: .isDirectory) }
            .flatMap { context.exists($0) ? $0 : nil } ?? fallback

        let values = parseINI(context.readText(url.appending(path: "config.ini")) ?? "")
        let sysdir = values["image.sysdir.1"]
        let target = values["target"]
        let display = (values["avd.ini.displayname"] ?? name).replacingOccurrences(of: "_", with: " ")
        return AVDConfig(
            name: name,
            displayName: display,
            url: url,
            systemImagePath: sysdir,
            apiLevel: target.flatMap(apiLevel) ?? sysdir.flatMap(apiLevel),
            deviceType: values["hw.device.name"])
    }
}
