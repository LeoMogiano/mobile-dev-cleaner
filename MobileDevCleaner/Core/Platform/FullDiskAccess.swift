import Foundation

protocol FullDiskAccessChecking: Sendable {
    func isGranted() async -> Bool
}

/// macOS has no API for this permission: reading a TCC-protected file is the reliable probe.
struct FullDiskAccessChecker: FullDiskAccessChecking {
    let probeURL: URL

    init(probeURL: URL = URL(filePath: "/Library/Application Support/com.apple.TCC/TCC.db")) {
        self.probeURL = probeURL
    }

    func isGranted() async -> Bool {
        let path = probeURL.path
        return await Task.detached {
            let fd = open(path, O_RDONLY)
            guard fd >= 0 else { return false }
            close(fd)
            return true
        }.value
    }
}
