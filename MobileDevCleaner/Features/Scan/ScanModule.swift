import Foundation

@MainActor
enum ScanModule {
    static func register() {
        sl.registerLazySingleton(ScanContext.self) {
            let paths: PathProvider = sl()
            let access: any FullDiskAccessChecking = sl()
            return ScanContext(
                paths: paths, sizes: sl(), runner: sl(), plist: sl(), probe: sl(),
                flutter: FlutterProjectFinder(home: paths.home, hasFullDiskAccess: { await access.isGranted() }))
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
        FlutterProjectsScanner(), PubCacheScanner(), FlutterSdkCacheScanner(), FvmVersionsScanner(),
    ]
}
