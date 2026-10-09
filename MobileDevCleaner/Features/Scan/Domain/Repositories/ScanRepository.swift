import Foundation

protocol ScanRepository: Sendable {
    /// Emits each category as soon as it is measured, then `.finished`.
    func scan(tools: Set<Tool>) -> AsyncStream<ScanEvent>
    /// Drops cached sizes after a cleanup.
    func invalidateSizes(of urls: [URL]) async
}
