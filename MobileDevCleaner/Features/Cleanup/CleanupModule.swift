import Foundation

@MainActor
enum CleanupModule {
    static func register() {
        sl.registerLazySingleton((any CleanupRepository).self) {
            let paths: PathProvider = sl()
            return CleanupRepositoryImpl(
                guardrail: PathGuard(paths: paths), trash: sl(), runner: sl(), probe: sl(), sizes: sl())
        }
        sl.registerFactory(BuildCleanupPlanUseCase.self) { BuildCleanupPlanUseCase() }
        sl.registerFactory(ExecuteCleanupUseCase.self) { ExecuteCleanupUseCase(repository: sl()) }
        sl.registerFactory(CheckBlockingAppsUseCase.self) { CheckBlockingAppsUseCase(repository: sl()) }
    }
}
