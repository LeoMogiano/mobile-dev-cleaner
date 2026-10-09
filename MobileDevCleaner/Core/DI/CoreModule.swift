import Foundation

@MainActor
enum CoreModule {
    static func register() {
        sl.registerLazySingleton(PathProvider.self) { PathProvider() }
        sl.registerLazySingleton((any ProcessRunning).self) { ProcessRunner() }
        sl.registerLazySingleton((any SizeCalculating).self) {
            let paths: PathProvider = sl()
            return SizeCalculator(cacheURL: paths.sizeCacheFile)
        }
        sl.registerLazySingleton((any TrashServicing).self) { TrashService() }
        sl.registerLazySingleton((any PlistReading).self) { PlistReader() }
        sl.registerLazySingleton((any CleanupNotifying).self) { NotificationService() }
        sl.registerLazySingleton((any ProcessProbing).self) {
            let runner: any ProcessRunning = sl()
            return ProcessProbe(runner: runner)
        }
    }
}
