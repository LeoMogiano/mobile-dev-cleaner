import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("ProcessProbe")
struct ProcessProbeTests {
    @Test("parse detects Xcode executable")
    func parseXcode() {
        let psOutput = "/Applications/Xcode.app/Contents/MacOS/Xcode"
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.xcode))
        #expect(!result.apps.contains(.simulator))
        #expect(!result.apps.contains(.androidStudio))
        #expect(!result.apps.contains(.androidEmulator))
    }

    @Test("parse detects Xcode-beta")
    func parseXcodeBeta() {
        let psOutput = "/Applications/Xcode-beta.app/Contents/MacOS/Xcode"
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.xcode))
    }

    @Test("parse detects Simulator")
    func parseSimulator() {
        let psOutput = "/Applications/Simulator.app/Contents/MacOS/Simulator"
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.simulator))
    }

    @Test("parse detects Android Studio by path")
    func parseAndroidStudioPath() {
        let psOutput = "/Applications/Android Studio.app/Contents/MacOS/studio"
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.androidStudio))
    }

    @Test("parse detects Android Studio by studio.sh")
    func parseAndroidStudioSh() {
        let psOutput = "/home/user/android-studio/bin/studio.sh"
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.androidStudio))
    }

    @Test("parse detects emulator with @name")
    func parseEmulatorAtName() {
        let psOutput = "qemu-system-aarch64 -avd Pixel_7_API_34 @Pixel_7_API_34"
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.androidEmulator))
        #expect(result.runningAVDs.contains("Pixel_7_API_34"))
    }

    @Test("parse detects emulator with -avd")
    func parseEmulatorAvdFlag() {
        let psOutput = "emulator64-arm -avd Pixel_8 -netfast"
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.androidEmulator))
        #expect(result.runningAVDs.contains("Pixel_8"))
    }

    @Test("parse detects emulator-headless")
    func parseEmulatorHeadless() {
        let psOutput = "emulator-headless -avd CI_Device -netfast"
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.androidEmulator))
        #expect(result.runningAVDs.contains("CI_Device"))
    }

    @Test("parse ignores unrelated lines")
    func parseUnrelated() {
        let psOutput = "/usr/bin/xcode-select -p\n/usr/bin/python3"
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.isEmpty)
        #expect(result.runningAVDs.isEmpty)
    }

    @Test("parse handles multiple processes")
    func parseMultiple() {
        let psOutput = """
        /Applications/Xcode.app/Contents/MacOS/Xcode
        /Applications/Simulator.app/Contents/MacOS/Simulator
        qemu-system-aarch64 -avd Device1
        emulator64-arm -avd Device2
        /Applications/Android Studio.app/Contents/MacOS/studio
        """
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.xcode))
        #expect(result.apps.contains(.simulator))
        #expect(result.apps.contains(.androidEmulator))
        #expect(result.apps.contains(.androidStudio))
        #expect(result.runningAVDs.contains("Device1"))
        #expect(result.runningAVDs.contains("Device2"))
    }

    @Test("runningApps gets processes via MockProcessRunner")
    func runningAppsMock() async throws {
        let psOutput = "/Applications/Xcode.app/Contents/MacOS/Xcode\n/Applications/Simulator.app/Contents/MacOS/Simulator"
        let mockRunner = MockProcessRunner { _, _ in
            ProcessResult(exitCode: 0, stdout: psOutput, stderr: "")
        }

        let probe = ProcessProbe(runner: mockRunner)
        let result = await probe.runningApps()

        #expect(result.apps.contains(.xcode))
        #expect(result.apps.contains(.simulator))
    }

    @Test("runningApps returns empty if ps fails")
    func runningAppsFailure() async throws {
        let mockRunner = MockProcessRunner { _, _ in
            ProcessResult(exitCode: 1, stdout: "", stderr: "error")
        }

        let probe = ProcessProbe(runner: mockRunner)
        let result = await probe.runningApps()

        #expect(result.isEmpty)
    }

    @Test("parse detects Flutter tools via flutter_tools.snapshot")
    func parseFlutterToolsSnapshot() {
        let psOutput = "/usr/bin/dartaotruntime /some/path/flutter_tools.snapshot build"
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.flutterTool))
    }

    @Test("parse detects Flutter tools via dart and frontend_server")
    func parseFlutterToolsFrontendServer() {
        let psOutput = "/usr/bin/dart /flutter/bin/snapshots/frontend_server.dart.snapshot --aot"
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.flutterTool))
    }

    @Test("parse ignores plain dart without frontend_server")
    func parsePlainDart() {
        let psOutput = "/usr/bin/dart my_script.dart"
        let result = ProcessProbe.parse(psOutput)

        #expect(!result.apps.contains(.flutterTool))
    }

    @Test("parse handles Flutter with other processes")
    func parseFlutterWithOthers() {
        let psOutput = """
        /Applications/Xcode.app/Contents/MacOS/Xcode
        /usr/bin/dartaotruntime /flutter/bin/cache/dart-sdk/bin/snapshots/flutter_tools.snapshot build
        /Applications/Simulator.app/Contents/MacOS/Simulator
        """
        let result = ProcessProbe.parse(psOutput)

        #expect(result.apps.contains(.xcode))
        #expect(result.apps.contains(.flutterTool))
        #expect(result.apps.contains(.simulator))
    }
}
