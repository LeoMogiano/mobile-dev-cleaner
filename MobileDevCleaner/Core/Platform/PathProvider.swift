import Foundation

/// Root URLs for all paths the app reads. Injectable so tests use temp home
/// and never touch user's real disk.
struct PathProvider: Sendable, Equatable {
    let home: URL
    let systemLibrary: URL

    init(
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        systemLibrary: URL = URL(filePath: "/Library", directoryHint: .isDirectory)
    ) {
        self.home = home
        self.systemLibrary = systemLibrary
    }

    var library: URL { home.appending(path: "Library", directoryHint: .isDirectory) }
    var caches: URL { library.appending(path: "Caches", directoryHint: .isDirectory) }
    var logs: URL { library.appending(path: "Logs", directoryHint: .isDirectory) }
    var applicationSupport: URL { library.appending(path: "Application Support", directoryHint: .isDirectory) }
    var preferences: URL { library.appending(path: "Preferences", directoryHint: .isDirectory) }
    var developer: URL { library.appending(path: "Developer", directoryHint: .isDirectory) }
    var xcode: URL { developer.appending(path: "Xcode", directoryHint: .isDirectory) }

    var derivedData: URL { xcode.appending(path: "DerivedData", directoryHint: .isDirectory) }
    var archives: URL { xcode.appending(path: "Archives", directoryHint: .isDirectory) }
    var previews: URL { xcode.appending(path: "UserData/Previews", directoryHint: .isDirectory) }
    var coreSimulatorDevices: URL { developer.appending(path: "CoreSimulator/Devices", directoryHint: .isDirectory) }
    var coreSimulatorCaches: URL { developer.appending(path: "CoreSimulator/Caches", directoryHint: .isDirectory) }
    var cocoapodsRepos: URL { home.appending(path: ".cocoapods/repos", directoryHint: .isDirectory) }

    var xcodePreferencesPlist: URL { preferences.appending(path: "com.apple.dt.Xcode.plist") }
    var systemRuntimes: URL { systemLibrary.appending(path: "Developer/CoreSimulator/Profiles/Runtimes", directoryHint: .isDirectory) }

    var gradle: URL { home.appending(path: ".gradle", directoryHint: .isDirectory) }
    var android: URL { home.appending(path: ".android", directoryHint: .isDirectory) }
    var avd: URL { android.appending(path: "avd", directoryHint: .isDirectory) }
    var androidSdk: URL { library.appending(path: "Android/sdk", directoryHint: .isDirectory) }
    var pubCache: URL { home.appending(path: ".pub-cache", directoryHint: .isDirectory) }
    var fvm: URL { home.appending(path: "fvm", directoryHint: .isDirectory) }
    var fvmVersions: URL { fvm.appending(path: "versions", directoryHint: .isDirectory) }

    var kotlinDaemon: URL { home.appending(path: ".kotlin/daemon", directoryHint: .isDirectory) }

    var trash: URL { home.appending(path: ".Trash", directoryHint: .isDirectory) }

    var appCacheDirectory: URL { caches.appending(path: "com.mogiteam.mdc", directoryHint: .isDirectory) }
    var sizeCacheFile: URL { appCacheDirectory.appending(path: "sizes.json") }

    var appSupportDirectory: URL { applicationSupport.appending(path: "com.mogiteam.mdc", directoryHint: .isDirectory) }
    var historyFile: URL { appSupportDirectory.appending(path: "history.json") }
}
