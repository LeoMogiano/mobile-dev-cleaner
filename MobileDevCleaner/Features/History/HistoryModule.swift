import Foundation

@MainActor
enum HistoryModule {
    static func register() {
        sl.registerLazySingleton((any HistoryLocalDataSource).self) {
            let paths: PathProvider = sl()
            return HistoryLocalDataSourceImpl(fileURL: paths.historyFile)
        }
        sl.registerLazySingleton((any HistoryRepository).self) {
            HistoryRepositoryImpl(dataSource: sl())
        }
        sl.registerFactory(LoadHistoryUseCase.self) { LoadHistoryUseCase(repository: sl()) }
        sl.registerFactory(RecordCleanupUseCase.self) { RecordCleanupUseCase(repository: sl()) }
    }
}
