import Foundation

struct ScanUseCase: Sendable {
    private let repository: any ScanRepository

    init(repository: any ScanRepository) {
        self.repository = repository
    }

    func callAsFunction(tools: Set<Tool> = Set(Tool.allCases)) -> AsyncStream<ScanEvent> {
        repository.scan(tools: tools)
    }
}
