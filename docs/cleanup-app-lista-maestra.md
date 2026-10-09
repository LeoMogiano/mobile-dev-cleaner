# Cleanup App — Lista maestra de rutas

**Proyecto:** Aplicación macOS para detectar, analizar y eliminar basura de herramientas de desarrollo (Xcode y Android Studio).

**Filosofía:** Detectar y analizar antes de borrar. No hay wipes ciegos — el usuario decide basándose en información clara y desagregada.

**Alcance intencional:** la app solo contempla dos categorías — basura clara (🟢) y basura opcional con trade-off (🟡). Todo lo que implique riesgo real (keystores, certificados, perfiles de firma, backups de dispositivos, llaves ADB, licencias aceptadas, binarios críticos como `adb`, runtimes activos) queda **fuera del escaneo**. La app nunca los lista como candidatos ni los muestra en el resumen. Si el usuario quiere tocar esos archivos, los gestiona por su cuenta.

---

## 1. Modelo de clasificación (2 niveles)

| Nivel | Significado | Comportamiento en UI |
|---|---|---|
| 🟢 **GREEN** | Basura real. Regenerable sin costo. | Auto-check por defecto. |
| 🟡 **YELLOW** | Basura opcional. Regenerable con costo (re-descargas, rebuilds lentos, pérdida de estado de emulador/simulador). | Seleccionable, con aviso del costo esperado. |

**Principio de agrupación:** la app trabaja a nivel de **carpeta** por defecto. Un usuario no necesita marcar/desmarcar 8 subfolders si todos son del mismo nivel — le basta con marcar la carpeta padre. Solo se desagrega a archivos individuales cuando **una misma carpeta contiene elementos de niveles distintos** (hoy solo aplica a AVDs en §4.2 y Simulators en §3.2).

---

## 2. Heurísticas de detección

1. **Detección de versión activa.** Para cualquier directorio segmentado por versión (Gradle, NDK, cmake, build-tools, system-images, platforms, carpetas del IDE), leer los proyectos del usuario para identificar versiones en uso. Las demás se degradan a 🟢.
2. **Fuentes de verdad para "proyectos activos":**
   - Xcode: `~/Library/Preferences/com.apple.dt.Xcode.plist` → `IDERecentWorkspaceDocuments`
   - Android Studio: `~/Library/Application Support/Google/AndroidStudio*/options/recentProjects.xml`
3. **CLI oficial como acción preferida.** Cuando existe (`xcrun simctl`, `avdmanager`, `sdkmanager`), la app los invoca en vez de `rm -rf`. Evita referencias huérfanas en metadata del sistema.
4. **Dry-run obligatorio.** Calcular y mostrar tamaños antes de cualquier borrado. Permitir exportar log.
5. **Contenedores con estados múltiples** (excepción a la agrupación por carpeta). AVDs (§4.2) y Simulators (§3.2) son contenedores cuyo contenido interno tiene niveles distintos y, por tanto, acciones distintas — limpieza / reset / eliminación. Aportan valor real al usuario.

---

## 3. XCODE (macOS)

### 3.1 Carpetas de basura directa — 🟢

| Ruta | Nivel | Notas |
|---|---|---|
| `~/Library/Developer/Xcode/DerivedData/` | 🟢 | Builds intermedios por proyecto. Suele ser lo más pesado. Incluye `ModuleCache/` internamente — no se trata aparte. |
| `~/Library/Developer/CoreSimulator/Caches/` | 🟢 | Caché del simulador (incluye `dyld/`). Distinto de `Devices/` (§3.2). Puede ocupar decenas de GB. |
| `~/Library/Logs/CoreSimulator/` | 🟢 | Logs del simulador. |
| `~/Library/Caches/com.apple.dt.Xcode/` | 🟢 | Caché de Xcode. |
| `~/Library/Caches/org.swift.swiftpm/` | 🟢 | Swift Package Manager cacheado. |
| `~/Library/Caches/com.apple.amp.itmstransporter/` | 🟢 | iTunes Transporter (subidas a App Store). Típicamente 1–3 GB si ha habido submissions. |
| `~/Library/Developer/XCPGDevices/` | 🟢 | Artefactos de Playgrounds. |
| `~/Library/Developer/Xcode/Packages/` | 🟢 | Metadata de Swift Packages. Baja prioridad (suele ser pequeño). |
| `~/Library/Developer/Xcode/DeveloperDiskImages/` | 🟢 | Disk images de soporte iOS. Se re-descargan al conectar un device físico. |
| `~/Library/Developer/Xcode/DVTDownloads/` | 🟢 | Developer Toolkit downloads. Suele estar vacío. |
| `~/Library/Developer/Xcode/UserData/IDEEditorInteractivityHistory/` | 🟢 | Historial del editor. |
| `~/Library/Developer/Xcode/UserData/IB Support/` | 🟢 | Caché de Interface Builder. |
| `~/Library/Developer/Shared/Documentation/DocSets/` | 🟢 | Docsets legacy (pre-Xcode 9). Raro, pero si existe puede ser pesado. |

### 3.2 Simuladores iOS — contenedor con estrategias

**Lo más pesado del lado Xcode.** `~/Library/Developer/CoreSimulator/Devices/` contiene cada iPhone/iPad/Watch simulado como una subcarpeta con UUID. Cada device: sistema, apps instaladas, SQLite, caches, logs — típicamente 1–3 GB por device, totales de 4–10 GB normales. **Mismo patrón que AVDs en §4.2.**

Ruta raíz: `~/Library/Developer/CoreSimulator/Devices/<UUID>/`

**Estrategia A — Borrar simuladores huérfanos** (de runtimes ya desinstalados)
- Comando: `xcrun simctl delete unavailable`
- Nivel: 🟢
- Qué libera: devices que apuntan a runtimes iOS/watchOS/tvOS ya eliminados. Nunca están en uso.

**Estrategia B — Borrar simuladores específicos** (por UUID / nombre)
- Detección: `xcrun simctl list devices --json` para enumerar con nombres, estado y runtime.
- Comando: `xcrun simctl delete <UUID>`
- Nivel: 🟡
- Cuándo: el device tiene apps o datos que el usuario podría querer conservar.

**Estrategia C — Reset de contenido** (mantiene los devices, pierde apps/datos)
- Comando: `xcrun simctl erase all` (o `erase <UUID>`)
- Nivel: 🟡
- Equivale al *"Erase All Content and Settings"* del menú del simulador.

**Estrategia D — Nuclear** (no recomendada si A/B/C aplican)
- Comando: `rm -rf ~/Library/Developer/CoreSimulator/Devices/*`
- Nivel: 🟡 con warning fuerte
- Xcode re-crea devices default al abrir Settings → Platforms.

**Alternativa GUI oficial:** Xcode → Settings → Platforms → expandir runtime → Delete. Invoca internamente `simctl delete`.

**Breakdown visual recomendado:** desagregar por UUID y mostrar nombre + tamaño (`iPhone 15 Pro — 2.1 GB`, `iPad Air — 1.3 GB`). Nunca mostrar `Devices → 4.9 GB` como bloque opaco.

### 3.3 Carpetas con análisis previo — 🟡

| Ruta | Nivel | Notas |
|---|---|---|
| `~/Library/Developer/Xcode/Archives/` | 🟡 | `.xcarchive` por app y fecha. Agrupar por bundle ID + fecha y **mostrar como referencia**, nunca auto-check (pueden ser submissions a App Store). |
| `~/Library/Developer/Xcode/iOS DeviceSupport/` | 🟡 | Símbolos por versión de iOS. Conservar versiones activas. |
| `~/Library/Developer/Xcode/watchOS DeviceSupport/` | 🟡 | Ídem. |
| `~/Library/Developer/Xcode/tvOS DeviceSupport/` | 🟡 | Ídem. |
| `~/Library/Developer/Xcode/visionOS DeviceSupport/` | 🟡 | Ídem. |
| `/Library/Developer/CoreSimulator/Profiles/Runtimes/` | 🟡 | **Ojo: `/Library`, no `~/Library`.** Runtimes iOS/watchOS/tvOS (~7 GB c/u). Usar `xcrun simctl runtime delete unavailable`. |
| `~/Library/Developer/Xcode/UserData/Previews/` | 🟡 | **No borrar con `rm`** — usar `xcrun simctl --set previews delete all`. |
| `~/.cocoapods/repos/` | 🟡 | Specs repo de CocoaPods. Puede ser 2+ GB. Re-descargar toma tiempo. |

### 3.4 Herramientas CLI recomendadas

- `xcrun simctl list devices --json` — enumeración estructurada
- `xcrun simctl delete unavailable` — borrar simuladores huérfanos
- `xcrun simctl runtime list`
- `xcrun simctl runtime delete unavailable`
- `xcrun simctl --set previews delete all`

### 3.5 Extras del ecosistema iOS

| Ruta | Nivel | Notas |
|---|---|---|
| `~/Library/Caches/CocoaPods/` | 🟢 | Caché de descargas de CocoaPods. |
| `~/Library/Caches/org.carthage.CarthageKit/` | 🟢 | Caché de Carthage. |
| `~/.fastlane/` | 🟢 | Caché de Fastlane (si lo usa el usuario). |
| Por proyecto (escaneo recursivo): `DerivedData/` custom, `Pods/`, `Carthage/Build/`, `*.xcworkspace/xcuserdata/`, `*.xcodeproj/xcuserdata/` | 🟢 | Escaneo recursivo de proyectos del usuario. |

---

## 4. ANDROID STUDIO

### 4.1 `~/.gradle/` — caché de Gradle

**Agrupación:** el contenido de `~/.gradle/caches/` es todo 🟢 excepto `modules-2/` que es 🟡. No se desagregan los subfolders internos (`groovy-dsl`, `fileHashes`, `fileContent`, `generated-gradle-jars`, `expanded`, `file-changes`, `dependencies-accessors`, carpetas de versión como `8.14/`) porque son uniformemente 🟢 y el usuario no gana nada eligiéndolos individualmente.

| Ruta | Nivel | Notas |
|---|---|---|
| `~/.gradle/caches/` (excluyendo `modules-2/`) | 🟢 | Todo temp + metadata + scripts transformados. Crece sin control. Recupera GB. |
| `~/.gradle/caches/modules-2/` | 🟡 | Dependencias Maven/Google descargadas. Borrar = re-descarga completa en el próximo build. |
| `~/.gradle/daemon/` | 🟢 | Logs de daemon. |
| `~/.gradle/native/`, `~/.gradle/notifications/` | 🟢 | Auxiliares. |
| `~/.gradle/jdks/` | 🟡 | JDKs de toolchains — detectar cuáles están en uso. |
| `~/.gradle/wrapper/dists/` | 🟡 | Versiones de Gradle descargadas. Detectar versión activa desde `gradle-wrapper.properties` de proyectos. |
| `~/.kotlin/daemon/` | 🟢 | Kotlin daemon logs (fuera de `~/.gradle/`, agregado aquí por coherencia temática). |

### 4.2 `~/.android/` — caches y emuladores

#### Caches — 🟢

| Ruta | Nivel | Notas |
|---|---|---|
| `~/.android/cache/` | 🟢 | Metadata de descargas del SDK (incluye `sdkbin-*`, `sdkinf-*`). |
| `~/.android/build-cache/` | 🟢 | Build cache compartido. |
| `~/.android/metrics/` | 🟢 | Analytics (si está activo). Mínimo. |

#### AVDs — contenedor con 3 estrategias

Ruta: `~/.android/avd/<nombre>.avd/`. Cada AVD contiene:
- `userdata-qemu.img` / `userdata-qemu.img.qcow2` — **el 80% del peso**, 2–6 GB
- `userdata.img`, `sdcard.img` — resto del estado del emulador
- `snapshots/`, `cache.img`, `cache.img.qcow2`, `tmpAdbCmds/` — temporales puros

**Estrategia A — Limpieza conservadora** (mantiene AVD + apps + estado)
- Borrar: `snapshots/`, `cache.img*`, `tmpAdbCmds/`
- Nivel: 🟢

**Estrategia B — Reset del emulador** (mantiene AVD, pierde apps y estado)
- Borrar: `userdata-qemu.img*`, `userdata.img`, `sdcard.img`
- Nivel: 🟡
- Destacar visualmente `userdata-qemu.img` — es típicamente la barra más larga del breakdown.

**Estrategia C — Eliminar AVD completa**
- Borrar: `<nombre>.avd/` + `<nombre>.ini` (par obligatorio)
- Comando preferido: `avdmanager delete avd -n <nombre>`
- Nivel: 🟡

**Detección:** `emulator -list-avds` para enumerar; leer `config.ini` de cada AVD para mapear AVD → `system-image` (cruzar con §4.3).

**Breakdown visual recomendado:** cada AVD como tarjeta expandible con breakdown interno y tres botones (`Limpiar` 🟢 / `Resetear` 🟡 / `Eliminar` 🟡).

### 4.3 `~/Library/Android/sdk/` — SDK root

**Patrón transversal — "versiones acumuladas":** varias subcarpetas están segmentadas por versión y nunca se limpian solas. La app detecta versión activa (desde `compileSdk`, `gradle files`, AVDs en uso) y ofrece limpieza del resto.

| Ruta | Nivel | Notas |
|---|---|---|
| `~/Library/Android/sdk/system-images/` | 🟡 | **Típicamente lo más pesado del SDK.** 1–3 GB por API × arquitectura. Cruzar con AVDs en uso (§4.2). |
| `~/Library/Android/sdk/ndk/` | 🟡 | Cada NDK ~1 GB+. Conservar solo los declarados en proyectos. |
| `~/Library/Android/sdk/cmake/` | 🟡 | Varias versiones; generalmente basta la más reciente. |
| `~/Library/Android/sdk/build-tools/` | 🟡 | Conservar la usada por proyectos + la más reciente. |
| `~/Library/Android/sdk/platforms/` | 🟡 | `android-XX` por API. Comparar con `compileSdk`. |
| `~/Library/Android/sdk/emulator/` | 🟡 | Binarios del emulador. Reinstalable vía SDK Manager. |
| `~/Library/Android/sdk/tools/` | 🟡 | Tools deprecados (reemplazados por `cmdline-tools`). Borrable si no se usa nada legacy. |
| `~/Library/Android/sdk/extras/` | 🟢 | Antiguos Google Play Services / repos de soporte. Hoy casi todo vive en Maven. |
| `~/Library/Android/sdk/skins/` | 🟢 | Skins visuales de emulador. Reinstalables. |
| `~/Library/Android/sdk/sources/` | 🟢 | Código fuente de APIs (solo para *step into*). |
| `~/Library/Android/sdk/fonts/` | 🟢 | Auxiliares. |
| `~/Library/Android/sdk/icons/` | 🟢 | Auxiliares. |
| `~/Library/Android/sdk/add-ons/` | 🟢 | Add-ons de fabricantes antiguos. |
| `~/Library/Android/sdk/docs/` | 🟢 | Docs descargadas. |
| `~/Library/Android/sdk/samples/` | 🟢 | Samples descargados. |
| `~/Library/Android/sdk/emu-update-last-check.ini` | 🟢 | Marcador de última verificación. |
| `~/Library/Android/sdk/modem-nv-ram-5554` | 🟢 | Metadata de modem de emulador. |

### 4.4 IDE caches y versiones huérfanas de Android Studio

**Patrón crítico — "versiones coexistiendo":** Android Studio crea carpetas con sufijo de versión (`AndroidStudio2025.3.3`, `AndroidStudio2025.3.2`, etc.) en varias rutas. Al actualizar, las versiones anteriores quedan huérfanas sin aviso.

Ejemplo real:
```
AndroidStudio2025.3.3/  (~631 MB)  ← versión activa (no se toca)
AndroidStudio2025.3.2/  (~572 MB)  ← huérfana, 🟢
```

**Heurística:** parsear los sufijos `<versión>`, ordenar por semver, considerar la más reciente como activa (queda fuera del escaneo para `Application Support` y `Preferences`), y marcar el resto como 🟢.

**Soporte oficial:** Android Studio incluye el diálogo *"Delete Unused Android Studio Directories"* al primer arranque tras update mayor — la app replica la misma lógica.

| Ruta | Aplica a | Nivel |
|---|---|---|
| `~/Library/Caches/Google/AndroidStudio<ver>/` | Cualquier versión | 🟢 |
| `~/Library/Caches/JetBrains/AndroidStudio<ver>/` | Cualquier versión | 🟢 |
| `~/Library/Logs/Google/AndroidStudio<ver>/` | Cualquier versión | 🟢 |
| `~/Library/Application Support/Google/AndroidStudio<ver>/` | **Solo versiones huérfanas** | 🟢 |
| `~/Library/Preferences/AndroidStudio<ver>` | **Solo versiones huérfanas** | 🟢 |

### 4.5 Herramientas CLI recomendadas

- `emulator -list-avds` — enumerar AVDs
- `avdmanager list avd` — detalle
- `avdmanager delete avd -n <nombre>` — borrado limpio
- `sdkmanager --list_installed` — paquetes registrados
- `sdkmanager --uninstall "system-images;android-30;google_apis;x86_64"`

### 4.6 Nivel proyecto — escaneo recursivo

| Patrón | Nivel | Notas |
|---|---|---|
| `**/build/` (proyectos Android/Gradle) | 🟢 | Build artifacts por proyecto. |
| `**/.gradle/` dentro de proyectos | 🟢 | Cache local por proyecto. |
| `**/app/build/`, `**/*/build/` | 🟢 | Multi-módulo Android. |
| `**/node_modules/` (RN/Capacitor/Ionic) | 🟡 | Opcional; sugerir solo si `package-lock.json` lleva tiempo sin modificarse. |

---

## 5. Patrones de UX aprendidos

### 5.1 Contenedor con estados múltiples
Única excepción a "agrupar por carpeta". Aplica a AVDs y Simulators — contenedores de instancias, cada una con subarchivos de niveles distintos, que justifican múltiples acciones (limpieza suave / reset / eliminación).

### 5.2 Breakdown interno visible
Dentro de un contenedor con estados múltiples, siempre desagregar visualmente: `userdata-qemu.img 5.2 GB · snapshots 800 MB · cache 150 MB`. Nunca bloque opaco.

### 5.3 Versión activa como ancla
Para cualquier directorio segmentado por versión, determinar la versión activa antes de clasificar. Mostrar al usuario cuál se está preservando y por qué.

### 5.4 Fuera del scope
La app no muestra items que puedan generar riesgo real al borrar (keystores, certificados, llaves ADB, licencias, runtimes activos, binarios de adb/cmdline-tools, backups de dispositivos). Si el usuario quiere tocar algo de ese terreno, lo hace por su cuenta. La app es **honesta sobre su scope** — no fake protection ni falsas alertas.

---

## 6. Cross-platform (nota futura)

Xcode es exclusivo de macOS. Si la app soporta otros SO para Android:

**Windows**
- SDK: `%LOCALAPPDATA%\Android\Sdk`
- Gradle: `%USERPROFILE%\.gradle`
- AVDs: `%USERPROFILE%\.android\avd`

**Linux**
- SDK: `~/Android/Sdk`
- Gradle: `~/.gradle`
- AVDs: `~/.android/avd`

---

## 7. Pendiente / abierto para agregar

_Sección libre. Se alimenta conforme avance la investigación._

- [ ] _(agregar aquí lo que venga)_

---

*Changelog del scope:*
- *Modelo simplificado a 2 niveles (🟢 / 🟡). Items 🟠/🔴 quedan fuera del escaneo por decisión de producto.*
- *Agrupación por carpeta como default — subfolders individuales solo en contenedores con niveles mixtos (AVDs, Simulators).*
- *Rutas nuevas: iTunes Transporter cache, CocoaPods repos, Fastlane, Kotlin daemon, DocSets legacy.*
