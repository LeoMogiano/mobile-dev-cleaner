import Foundation

struct ExportPlanUseCase: Sendable {
    private let repository: any PlanTransferRepository

    init(repository: any PlanTransferRepository) {
        self.repository = repository
    }

    func callAsFunction(
        reports: [CategoryID: CategoryReport], candidateIDs: Set<String>, deviceActions: [String: DeviceAction]
    ) async -> Either<Failure, Data> {
        await repository.export(reports: reports, candidateIDs: candidateIDs, deviceActions: deviceActions)
    }
}

struct ImportPlanUseCase: Sendable {
    private let repository: any PlanTransferRepository

    init(repository: any PlanTransferRepository) {
        self.repository = repository
    }

    func callAsFunction(_ data: Data, reports: [CategoryID: CategoryReport]) async -> Either<Failure, PlanSelection> {
        await repository.importPlan(data, reports: reports)
    }
}
