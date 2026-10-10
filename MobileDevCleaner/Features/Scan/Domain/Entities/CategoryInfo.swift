import Foundation

/// Static copy per category, taken verbatim from `mkData()` in the prototype.
struct CategoryInfo: Sendable, Hashable {
    let id: CategoryID
    let name: String
    let technicalName: String
    /// Displayed root path ("~/Library/Developer/Xcode/DerivedData").
    let displayPath: String
    let symbol: String
    let whatIsIt: String
    let ifDeleted: String
    let comesBack: String
    let needsFullDiskAccess: Bool
}

extension CategoryInfo {
    static func info(for id: CategoryID) -> CategoryInfo {
        switch id {
        case .builds:
            return CategoryInfo(
                id: .builds,
                name: L10n.string("Builds de Xcode"),
                technicalName: L10n.string("DerivedData"),
                displayPath: "~/Library/Developer/Xcode/DerivedData",
                symbol: "gearshape.2",
                whatIsIt: L10n.string("Archivos intermedios que Xcode genera al compilar cada proyecto."),
                ifDeleted: L10n.string("El próximo build de ese proyecto tardará más: compila desde cero."),
                comesBack: L10n.string("Sí. Xcode lo regenera en cuanto compilas."),
                needsFullDiskAccess: false
            )
        case .caches:
            return CategoryInfo(
                id: .caches,
                name: L10n.string("Cachés y temporales"),
                technicalName: L10n.string("Caches · tmp"),
                displayPath: "~/Library/Caches/com.apple.dt.Xcode",
                symbol: "tray",
                whatIsIt: L10n.string("Cachés de Xcode, del simulador y archivos temporales de compilación."),
                ifDeleted: L10n.string("Xcode puede tardar unos segundos más en abrir la primera vez."),
                comesBack: L10n.string("Sí. Se recrean solos al usar Xcode."),
                needsFullDiskAccess: false
            )
        case .tests:
            return CategoryInfo(
                id: .tests,
                name: L10n.string("Residuos de test"),
                technicalName: L10n.string("XCTestDevices"),
                displayPath: "~/Library/Developer/XCTestDevices",
                symbol: "checklist",
                whatIsIt: L10n.string("Resultados y adjuntos de ejecuciones de tests (.xcresult)."),
                ifDeleted: L10n.string("Pierdes el historial de resultados de tests anteriores."),
                comesBack: L10n.string("Sí. Cada ejecución de tests genera nuevos."),
                needsFullDiskAccess: false
            )
        case .sims:
            return CategoryInfo(
                id: .sims,
                name: L10n.string("Simuladores iOS"),
                technicalName: L10n.string("CoreSimulator/Devices"),
                displayPath: "~/Library/Developer/CoreSimulator/Devices",
                symbol: "iphone",
                whatIsIt: L10n.string("Cada simulador guarda sus apps instaladas, datos, cachés y snapshots."),
                ifDeleted: L10n.string("Depende de la acción: limpiar conserva tus apps; restablecer o eliminar las borra."),
                comesBack: L10n.string("La caché sí. Los datos de tus apps no."),
                needsFullDiskAccess: false
            )
        case .runtimes:
            return CategoryInfo(
                id: .runtimes,
                name: L10n.string("Runtimes de simulador"),
                technicalName: L10n.string("CoreSimulator/Runtimes"),
                displayPath: "/Library/Developer/CoreSimulator/Profiles/Runtimes",
                symbol: "cube",
                whatIsIt: L10n.string("Sistemas operativos completos que usan los simuladores (iOS, watchOS…). Los que están en uso no aparecen."),
                ifDeleted: L10n.string("Si lo necesitas otra vez, Xcode lo vuelve a descargar (varios GB)."),
                comesBack: L10n.string("Solo si lo vuelves a descargar desde Xcode."),
                needsFullDiskAccess: true
            )
        case .devsup:
            return CategoryInfo(
                id: .devsup,
                name: L10n.string("Soporte de iPhones"),
                technicalName: L10n.string("iOS DeviceSupport"),
                displayPath: "~/Library/Developer/Xcode/iOS DeviceSupport",
                symbol: "iphone.and.arrow.forward",
                whatIsIt: L10n.string("Símbolos que Xcode copia de cada iPhone que conectas para depurar."),
                ifDeleted: L10n.string("La próxima vez que conectes ese iPhone, Xcode tardará unos minutos en prepararlo."),
                comesBack: L10n.string("Sí. Se vuelve a copiar al conectar el dispositivo."),
                needsFullDiskAccess: false
            )
        case .archives:
            return CategoryInfo(
                id: .archives,
                name: L10n.string("Archives"),
                technicalName: L10n.string("Archives"),
                displayPath: "~/Library/Developer/Xcode/Archives",
                symbol: "archivebox",
                whatIsIt: L10n.string("Versiones archivadas de tus apps (.xcarchive) con sus símbolos."),
                ifDeleted: L10n.string("Pierdes los símbolos para leer crashes de esas versiones."),
                comesBack: L10n.string("No. Solo se crean al archivar una nueva versión."),
                needsFullDiskAccess: false
            )
        case .previews:
            return CategoryInfo(
                id: .previews,
                name: L10n.string("SwiftUI Previews"),
                technicalName: L10n.string("UserData/Previews"),
                displayPath: "~/Library/Developer/Xcode/UserData/Previews",
                symbol: "eye",
                whatIsIt: L10n.string("Simuladores y builds que Xcode crea para mostrar las previews de SwiftUI."),
                ifDeleted: L10n.string("La primera preview tardará un poco más."),
                comesBack: L10n.string("Sí. Se regeneran al abrir una preview."),
                needsFullDiskAccess: false
            )
        case .pods:
            return CategoryInfo(
                id: .pods,
                name: L10n.string("CocoaPods · Carthage · Fastlane"),
                technicalName: L10n.string("Pods · Carthage · fastlane"),
                displayPath: "~/Library/Caches/CocoaPods",
                symbol: "shippingbox",
                whatIsIt: L10n.string("Cachés de los gestores de dependencias y herramientas de iOS."),
                ifDeleted: L10n.string("El próximo pod install o carthage bootstrap descargará de nuevo."),
                comesBack: L10n.string("Sí. Se rellenan al instalar dependencias."),
                needsFullDiskAccess: false
            )
        case .gcache:
            return CategoryInfo(
                id: .gcache,
                name: L10n.string("Cachés de Gradle"),
                technicalName: L10n.string("caches/transforms · build-cache"),
                displayPath: "~/.gradle/caches",
                symbol: "shippingbox",
                whatIsIt: L10n.string("Resultados intermedios que Gradle guarda para compilar más rápido."),
                ifDeleted: L10n.string("El próximo build tardará más."),
                comesBack: L10n.string("Sí. Gradle lo regenera al compilar."),
                needsFullDiskAccess: false
            )
        case .gdeps:
            return CategoryInfo(
                id: .gdeps,
                name: L10n.string("Dependencias de Gradle"),
                technicalName: L10n.string("caches/modules-2"),
                displayPath: "~/.gradle/caches/modules-2",
                symbol: "square.stack.3d.up",
                whatIsIt: L10n.string("Librerías descargadas (AndroidX, Kotlin, Firebase…) que usan tus proyectos."),
                ifDeleted: L10n.string("Gradle volverá a descargarlas en el próximo build (necesitas internet)."),
                comesBack: L10n.string("Sí, pero toca esperar la descarga."),
                needsFullDiskAccess: false
            )
        case .gvers:
            return CategoryInfo(
                id: .gvers,
                name: L10n.string("Versiones de Gradle"),
                technicalName: L10n.string("wrapper/dists"),
                displayPath: "~/.gradle/wrapper/dists",
                symbol: "square.on.square",
                whatIsIt: L10n.string("Distribuciones de Gradle que descarga el wrapper de cada proyecto."),
                ifDeleted: L10n.string("Un proyecto que use esa versión la descargará otra vez al abrirlo."),
                comesBack: L10n.string("Sí, al abrir un proyecto que la use."),
                needsFullDiskAccess: false
            )
        case .jdks:
            return CategoryInfo(
                id: .jdks,
                name: L10n.string("JDKs de Gradle"),
                technicalName: L10n.string("jdks"),
                displayPath: "~/.gradle/jdks",
                symbol: "cube",
                whatIsIt: L10n.string("JDKs que Gradle descarga automáticamente (toolchains)."),
                ifDeleted: L10n.string("Gradle los vuelve a descargar si un proyecto los pide."),
                comesBack: L10n.string("Sí, al compilar un proyecto que los pida."),
                needsFullDiskAccess: false
            )
        case .glogs:
            return CategoryInfo(
                id: .glogs,
                name: L10n.string("Logs de Gradle · Kotlin"),
                technicalName: L10n.string("daemon · kotlin"),
                displayPath: "~/.gradle/daemon",
                symbol: "doc.text",
                whatIsIt: L10n.string("Logs del daemon de Gradle y del compilador de Kotlin."),
                ifDeleted: L10n.string("Nada. Solo pierdes logs viejos."),
                comesBack: L10n.string("Sí. Se escriben con cada build."),
                needsFullDiskAccess: false
            )
        case .acache:
            return CategoryInfo(
                id: .acache,
                name: L10n.string("Cachés de Android"),
                technicalName: L10n.string(".android/cache"),
                displayPath: "~/.android/cache",
                symbol: "tray",
                whatIsIt: L10n.string("Cachés de Android Studio y de las herramientas del SDK."),
                ifDeleted: L10n.string("Android Studio puede tardar un poco más al indexar."),
                comesBack: L10n.string("Sí. Se regeneran solos."),
                needsFullDiskAccess: false
            )
        case .avds:
            return CategoryInfo(
                id: .avds,
                name: L10n.string("Emuladores Android"),
                technicalName: L10n.string("AVDs"),
                displayPath: "~/.android/avd",
                symbol: "iphone",
                whatIsIt: L10n.string("Cada emulador guarda apps, datos, caché y snapshots de arranque rápido."),
                ifDeleted: L10n.string("Limpiar conserva tus apps; restablecer o eliminar las borra."),
                comesBack: L10n.string("La caché y los snapshots sí. Los datos no."),
                needsFullDiskAccess: false
            )
        case .sysimg:
            return CategoryInfo(
                id: .sysimg,
                name: L10n.string("Imágenes de sistema"),
                technicalName: L10n.string("system-images"),
                displayPath: "~/Library/Android/sdk/system-images",
                symbol: "cube",
                whatIsIt: L10n.string("Sistemas Android que usan los emuladores para arrancar."),
                ifDeleted: L10n.string("Los emuladores que la usan no arrancarán hasta volver a descargarla."),
                comesBack: L10n.string("Solo si la vuelves a descargar desde el SDK Manager."),
                needsFullDiskAccess: false
            )
        case .ndk:
            return CategoryInfo(
                id: .ndk,
                name: L10n.string("NDK / cmake / build-tools"),
                technicalName: L10n.string("ndk · cmake · build-tools"),
                displayPath: "~/Library/Android/sdk",
                symbol: "wrench.adjustable",
                whatIsIt: L10n.string("Herramientas nativas del SDK. Las versiones viejas suelen quedarse olvidadas."),
                ifDeleted: L10n.string("Un proyecto que fije esa versión la descargará de nuevo."),
                comesBack: L10n.string("Sí, al compilar un proyecto que la pida."),
                needsFullDiskAccess: false
            )
        case .studio:
            return CategoryInfo(
                id: .studio,
                name: L10n.string("Versiones viejas de Studio"),
                technicalName: L10n.string("Application Support/Google"),
                displayPath: "~/Library/Application Support/Google",
                symbol: "clock",
                whatIsIt: L10n.string("Ajustes, plugins e índices de versiones de Android Studio que ya no usas."),
                ifDeleted: L10n.string("Pierdes los ajustes de esa versión. Tu versión actual no se toca."),
                comesBack: L10n.string("No. Son de versiones que ya no tienes."),
                needsFullDiskAccess: false
            )
        case .fprojects:
            return CategoryInfo(
                id: .fprojects,
                name: L10n.string("Proyectos Flutter"),
                technicalName: L10n.string("build/ · .dart_tool/"),
                displayPath: "~/…/pubspec.yaml",
                symbol: "square.stack",
                whatIsIt: L10n.string("Compilaciones y archivos de herramientas que Flutter guarda dentro de cada proyecto."),
                ifDeleted: L10n.string("La próxima compilación del proyecto tardará más. Tu código no se toca."),
                comesBack: L10n.string("Sí. Se regeneran al compilar o al correr flutter pub get."),
                needsFullDiskAccess: false
            )
        case .pubcache:
            return CategoryInfo(
                id: .pubcache,
                name: L10n.string("Caché de pub"),
                technicalName: L10n.string(".pub-cache"),
                displayPath: "~/.pub-cache",
                symbol: "shippingbox",
                whatIsIt: L10n.string("Todos los paquetes de Dart y Flutter que descargaste para tus proyectos."),
                ifDeleted: L10n.string("El próximo flutter pub get descargará de nuevo los paquetes que uses."),
                comesBack: L10n.string("Sí. Se rellena al instalar dependencias."),
                needsFullDiskAccess: false
            )
        case .fsdk:
            return CategoryInfo(
                id: .fsdk,
                name: L10n.string("Caché del SDK de Flutter"),
                technicalName: L10n.string("flutter/bin/cache"),
                displayPath: "flutter/bin/cache",
                symbol: "tray",
                whatIsIt: L10n.string("Motores y herramientas que el SDK de Flutter descarga para cada plataforma."),
                ifDeleted: L10n.string("El próximo comando de flutter los descargará de nuevo."),
                comesBack: L10n.string("Sí. Se descargan solos o con flutter precache."),
                needsFullDiskAccess: false
            )
        case .fvm:
            return CategoryInfo(
                id: .fvm,
                name: L10n.string("Versiones de Flutter (FVM)"),
                technicalName: L10n.string("fvm/versions"),
                displayPath: "~/fvm/versions",
                symbol: "square.on.square",
                whatIsIt: L10n.string("SDKs completos de Flutter instalados con FVM. Cada versión ocupa varios GB."),
                ifDeleted: L10n.string("Un proyecto que fije esa versión la descargará de nuevo con fvm install."),
                comesBack: L10n.string("Solo si un proyecto la vuelve a pedir."),
                needsFullDiskAccess: false
            )
        }
    }
}
