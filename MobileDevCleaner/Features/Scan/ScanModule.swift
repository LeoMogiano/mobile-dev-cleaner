import Foundation

@MainActor
enum ScanModule {
    static func register() {
        sl.registerLazySingleton(ScanContext.self) {
            ScanContext(paths: sl(), sizes: sl(), runner: sl(), plist: sl(), probe: sl())
        }
        sl.registerLazySingleton((any ScanRepository).self) {
            ScanRepositoryImpl(context: sl(), scanners: allScanners)
        }
        sl.registerFactory(ScanUseCase.self) {
            ScanUseCase(repository: sl())
        }
    }

    static let allScanners: [any CategoryScanner] = [
        DerivedDataScanner(), XcodeCachesScanner(), TestResiduesScanner(), SimulatorsScanner(),
        RuntimesScanner(), DeviceSupportScanner(), ArchivesScanner(), PreviewsScanner(),
        DependencyCachesScanner(), GradleCachesScanner(), GradleDependenciesScanner(),
        GradleVersionsScanner(), GradleJdksScanner(), GradleLogsScanner(), AndroidCachesScanner(),
        EmulatorsScanner(), SystemImagesScanner(), SdkToolsScanner(), StudioVersionsScanner(),
    ]
}
