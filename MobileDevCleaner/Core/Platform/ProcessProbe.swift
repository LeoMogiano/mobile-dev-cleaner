import Foundation

enum DevApp: String, Sendable, CaseIterable, Hashable {
    case xcode
    case simulator
    case androidStudio
    case androidEmulator
    case flutterTool
}

struct RunningApps: Sendable, Equatable {
    var apps: Set<DevApp> = []
    /// Running AVD names from `-avd <name>` or `@name` in emulator command line.
    var runningAVDs: Set<String> = []

    var isEmpty: Bool { apps.isEmpty }
}

protocol ProcessProbing: Sendable {
    func runningApps() async -> RunningApps
}

struct ProcessProbe: ProcessProbing {
    private let runner: any ProcessRunning

    init(runner: any ProcessRunning) {
        self.runner = runner
    }

    func runningApps() async -> RunningApps {
        do {
            let result = try await runner.run("/bin/ps", arguments: ["-axo", "command="])
            guard result.succeeded else {
                return RunningApps()
            }
            return Self.parse(result.stdout)
        } catch {
            return RunningApps()
        }
    }

    static func parse(_ psOutput: String) -> RunningApps {
        var apps: Set<DevApp> = []
        var runningAVDs: Set<String> = []

        for line in psOutput.split(separator: "\n", omittingEmptySubsequences: true) {
            let cmdLine = String(line)

            if cmdLine.contains("/Xcode") && cmdLine.contains(".app/Contents/MacOS/Xcode") {
                apps.insert(.xcode)
            }

            if cmdLine.contains("/Simulator.app/Contents/MacOS/Simulator") {
                apps.insert(.simulator)
            }

            if cmdLine.contains("/Android Studio.app/Contents/MacOS/studio") || cmdLine.contains("studio.sh") {
                apps.insert(.androidStudio)
            }

            if cmdLine.contains("qemu-system") || cmdLine.contains("emulator64") || cmdLine.contains("emulator-headless") {
                apps.insert(.androidEmulator)

                if let avdName = extractAVDName(from: cmdLine) {
                    runningAVDs.insert(avdName)
                }
            }

            if cmdLine.contains("flutter_tools.snapshot") ||
               (cmdLine.contains("dart") && cmdLine.contains("frontend_server")) {
                apps.insert(.flutterTool)
            }
        }

        return RunningApps(apps: apps, runningAVDs: runningAVDs)
    }

    private static func extractAVDName(from cmdLine: String) -> String? {
        if let range = cmdLine.range(of: "@([A-Za-z0-9_.\\-]+)", options: .regularExpression) {
            let matched = String(cmdLine[range])
            if matched.first == "@" {
                return String(matched.dropFirst())
            }
            return matched
        }

        let parts = cmdLine.split(separator: " ")
        for i in 0..<(parts.count - 1) {
            if parts[i] == "-avd" {
                return String(parts[i + 1])
            }
        }

        return nil
    }
}
