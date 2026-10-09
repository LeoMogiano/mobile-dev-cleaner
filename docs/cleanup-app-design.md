# Cleanup App — Documento de diseño

**Propósito de este documento:** especificación de diseño e implementación para la app de limpieza de herramientas de desarrollo. Se complementa con `cleanup-app-lista-maestra.md` (el *qué* — rutas y scope). Este documento cubre el *cómo* — arquitectura, UX, componentes SwiftUI, flujos.

**Consumidor objetivo:** agente de desarrollo (Claude Code u otro) que implementará la app. Debe ser accionable sin ambigüedad en decisiones arquitectónicas clave.

---

## 1. Visión y principios de producto

### 1.1 Qué es
Utilidad macOS nativa para escanear, analizar y limpiar archivos basura generados por Xcode y Android Studio (simuladores, AVDs, caches de Gradle, SDKs acumulados, artefactos de build, etc.). El valor diferencial vs herramientas genéricas de "clean my mac" es el **conocimiento de dominio específico de dev tools**.

### 1.2 Usuario objetivo
Desarrollador mobile (iOS, Android, o ambos) con Mac que ha acumulado GB de basura invisible. Conoce el terminal pero prefiere UI para tareas donde la confianza y el contexto importan.

### 1.3 Principios de producto

1. **Honesto sobre su scope.** La app nunca toca archivos de riesgo real (keystores, certificados, llaves ADB, licencias aceptadas, runtimes activos, backups de dispositivos). Ni los lista, ni los muestra, ni finge protegerlos. El silencio comunica el límite.
2. **Detecta antes de borrar.** Cero wipes ciegos. Todo candidato se analiza, se mide, se contextualiza (¿qué versión está activa? ¿qué AVD apunta a esta system-image?), y se presenta al usuario antes de cualquier acción destructiva.
3. **Default conservador.** Solo 🟢 GREEN queda pre-seleccionado. 🟡 YELLOW exige acción explícita del usuario.
4. **Dry-run obligatorio.** Entre "seleccionado" y "borrado" siempre hay una pantalla de confirmación con el total y la lista detallada.
5. **Agrupación por carpeta como default.** Subfolders individuales solo en contenedores con niveles mixtos (AVDs, Simulators).
6. **CLI oficial como primera opción de ejecución.** `xcrun simctl`, `avdmanager`, `sdkmanager` en vez de `rm -rf` cuando existan.

### 1.4 Principios de UX

- **Claridad sobre completitud.** Si una fila necesita dos líneas de explicación, la información está mal organizada.
- **Nada mágico.** El usuario siempre puede ver el path completo, el tamaño exacto, y la razón por la que algo está marcado 🟡 en vez de 🟢.
- **Reversibilidad donde existe.** Antes de acciones irreversibles (borrar AVD completa, borrar Archives), diálogo modal con resumen.
- **Nativo que parece nativo.** Usa atajos macOS estándar (⌘A, ⌘F, ⌘.), respeta modo oscuro, sigue el look de Ajustes del Sistema de macOS moderno.

---

## 2. Stack técnico

| Capa | Tecnología | Justificación |
|---|---|---|
| Lenguaje | Swift 5.9+ | Estándar Apple, macros, concurrency maduro. |
| UI | SwiftUI (macOS 14 Sonoma+) | Primitivas que necesitamos ya están todas nativas. Evita AppKit salvo excepciones. |
| Concurrencia | async / await + Task / TaskGroup | Escaneo paralelo de directorios sin bloquear UI. |
| Sistema de archivos | FileManager + `URLResourceValues` | Tamaños via `.totalFileAllocatedSizeKey` (recursivo) y `.isDirectoryKey`. |
| Procesos externos | `Foundation.Process` + `Pipe` | Invocar `xcrun`, `avdmanager`, `sdkmanager`. |
| Observabilidad | `@Observable` (Swift Observation) | En vez de `ObservableObject` + `@Published`. |
| Persistencia | `UserDefaults` + `@AppStorage` | Preferencias simples (últimos escaneos, opciones). No se guarda información del filesystem. |
| Distribución | Developer ID + Notarization (fuera de App Store) | El uso de rutas absolutas fuera del sandbox impide App Store sin trade-offs grandes. |

### 2.1 Target mínimo y binary
- **macOS 14.0+** (Sonoma). Permite uso sin parches de `NavigationSplitView`, `Inspector`, `ContentUnavailableView`, `@Observable`.
- Universal Binary (arm64 + x86_64).

### 2.2 Dependencias externas
**Ninguna.** Todo se resuelve con Foundation + SwiftUI. Más mantenible, más liviano, más fácil de distribuir.

---

## 3. Arquitectura

### 3.1 Capas

```
┌─────────────────────────────────────────┐
│  Views (SwiftUI)                         │
│  DashboardView, SectionView, etc.        │
└────────────────┬────────────────────────┘
                 │ bindings / events
┌────────────────▼────────────────────────┐
│  ViewModels (@Observable)                │
│  AppState, ScanViewModel, CleanupPlan    │
└────────────────┬────────────────────────┘
                 │ async calls
┌────────────────▼────────────────────────┐
│  Domain services                         │
│  ScanCoordinator, Cleaner, SizeCalc      │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  Scanners (per tool)                     │
│  XcodeScanner, AndroidScanner            │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  Platform adapters                       │
│  FileSystem, ProcessRunner, CLIWrappers  │
└─────────────────────────────────────────┘
```

### 3.2 Tipos de dominio clave

```swift
/// Nivel de riesgo. Solo dos valores — 🟠/🔴 están fuera del scope.
enum RiskLevel {
    case green    // 🟢 basura directa
    case yellow   // 🟡 basura con trade-off
}

/// Candidato de limpieza base.
struct CleanupCandidate: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let displayName: String
    let risk: RiskLevel
    let category: Category
    let tool: Tool                 // .xcode / .android
    let size: Int64                // bytes
    let reason: String             // por qué es 🟢 o 🟡
    let executionStrategy: ExecutionStrategy
    var selected: Bool
}

enum ExecutionStrategy {
    case remove(URL)                              // rm directo
    case cliCommand(executable: URL, args: [String])  // xcrun, avdmanager, etc.
    case containerAction(ContainerAction)         // ver abajo
}

/// Contenedores con múltiples estrategias (AVDs, Simulators).
struct ContainerCandidate: Identifiable {
    let id: UUID
    let name: String              // "Pixel_7_Pro", "iPhone 15 Pro"
    let kind: ContainerKind       // .avd / .iosSimulator
    let path: URL
    let totalSize: Int64
    let breakdown: [InternalComponent]
    let availableActions: [ContainerAction]
}

struct InternalComponent {
    let label: String             // "userdata-qemu.img"
    let size: Int64
    let role: ComponentRole       // .state / .cache / .snapshot
}

enum ContainerAction {
    case softClean               // 🟢 solo caches+snapshots+tmp
    case reset                   // 🟡 mantiene contenedor, pierde estado
    case delete                  // 🟡 elimina todo
}

/// Resultado de un escaneo completo.
struct ScanResult {
    let scannedAt: Date
    let xcode: ToolReport
    let android: ToolReport
    var totalReclaimable: Int64 {
        xcode.reclaimable + android.reclaimable
    }
}

struct ToolReport {
    let categories: [CategoryGroup]
    let reclaimable: Int64        // total seleccionado o seleccionable
}
```

### 3.3 Flujo principal (state machine)

```
 [Idle]
   │ user clicks "Escanear"
   ▼
 [Scanning] ─ (permiso denegado) ──→ [NeedsPermission]
   │ done
   ▼
 [ReviewingResults]
   │ user toggles selections
   ▼
 [ReviewingResults]
   │ user clicks "Limpiar"
   ▼
 [ConfirmingCleanup]      ← diálogo modal, dry-run summary
   │ confirm
   ▼
 [Cleaning] ─ (error) ──→ [CleanupPartial]
   │ done
   ▼
 [CleanupComplete]
   │ user clicks "Escanear de nuevo"
   ▼
 [Scanning]
```

---

## 4. Arquitectura de información y navegación

### 4.1 Layout principal

`NavigationSplitView` de tres columnas cuando hay selección activa, dos columnas en estado base.

```
┌───────────────┬──────────────────────────────┬─────────────────┐
│   Sidebar     │   Content                    │   Inspector     │
│               │                              │   (contextual)  │
│ ▸ Dashboard   │   [lista / detalle de la     │                 │
│ ▸ Xcode       │    categoría seleccionada]   │   Metadata del  │
│   · Caches    │                              │   ítem selecc.  │
│   · Simuladores│                             │                 │
│   · Versiones │                              │                 │
│ ▸ Android     │                              │                 │
│   · Gradle    │                              │                 │
│   · AVDs      │                              │                 │
│   · SDK       │                              │                 │
│               │                              │                 │
│ ──────────    │                              │                 │
│ ⚙ Ajustes    │                              │                 │
└───────────────┴──────────────────────────────┴─────────────────┘
```

- **Sidebar**: fija, agrupada por herramienta. Cada categoría muestra un badge con tamaño total recuperable.
- **Content**: cambia según la selección. Dashboard por default.
- **Inspector**: se abre con ⌘I o seleccionando un ítem. Muestra path completo, tamaño, razón de clasificación, comando que se ejecutará.

### 4.2 Toolbar principal

| Elemento | Acción | Atajo |
|---|---|---|
| Escanear / Re-escanear | Inicia scan | ⌘R |
| Progreso (mientras escanea) | ProgressView inline | — |
| Total recuperable (badge) | No clickeable, informativo | — |
| Limpiar seleccionados | Abre diálogo de confirmación | ⌘⏎ |
| Filtro (🟢 / 🟡 / todos) | Toggle | — |
| Buscar | Campo de búsqueda por path/nombre | ⌘F |

---

## 5. Pantallas

### 5.1 Onboarding / permisos

Se muestra la primera vez o cuando Full Disk Access no está concedido.

```
┌─────────────────────────────────────────────────┐
│                                                 │
│         [ícono grande: lupa sobre carpeta]      │
│                                                 │
│         Para escanear tu basura de dev,         │
│         la app necesita Acceso Total al Disco.  │
│                                                 │
│  Qué hace la app:                               │
│  • Lee tamaños de ~/Library/Developer,          │
│    ~/.gradle, ~/.android, ~/Library/Android     │
│  • Solo borra lo que tú marques y confirmes.    │
│                                                 │
│  Qué NO hace:                                   │
│  • No sube información a ningún servidor.       │
│  • No escanea tus documentos ni archivos        │
│    personales.                                  │
│                                                 │
│  [ Abrir Ajustes del Sistema ]   [ Por ahora no ]│
│                                                 │
└─────────────────────────────────────────────────┘
```

SwiftUI primitivas: `ContentUnavailableView`, `Button(action:)`, `Text`. El botón abre `x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles`.

### 5.2 Dashboard

Vista inicial post-escaneo.

```
┌─────────────────────────────────────────────────┐
│  Último escaneo: hace 2 min                     │
│                                                 │
│  ╔═════════════════════════════════════════╗    │
│  ║  Se puede liberar hasta   17.3 GB       ║    │
│  ║                                         ║    │
│  ║  [====== Xcode 11.2 GB =====][Android 6.1 GB]║
│  ╚═════════════════════════════════════════╝    │
│                                                 │
│  XCODE                                          │
│  Simuladores iOS (5)        4.9 GB  [Ver →]     │
│  DerivedData (8 proyectos)  3.1 GB  [Ver →]     │
│  iOS DeviceSupport (4)      2.2 GB  [Ver →]     │
│  Caches y temp              1.0 GB  [Ver →]     │
│                                                 │
│  ANDROID                                        │
│  System images (6 APIs)     3.4 GB  [Ver →]     │
│  AVDs (2)                   1.8 GB  [Ver →]     │
│  Gradle caches              0.9 GB  [Ver →]     │
│                                                 │
│  [Escanear de nuevo]     [Limpiar seleccionados]│
└─────────────────────────────────────────────────┘
```

### 5.3 Vista de categoría (caso: "DerivedData")

Lista plana de carpetas 🟢 con totales claros. Un único nivel de jerarquía.

```
┌─────────────────────────────────────────────────┐
│  DerivedData · 8 proyectos · 3.1 GB             │
│  [ Seleccionar todo ]    [ Deseleccionar todo ] │
│                                                 │
│  ☑ 🟢  Intramax-abc123           1.2 GB  [====] │
│         ~/.../DerivedData/Intramax-abc123       │
│                                                 │
│  ☑ 🟢  SwiftUI-Demo-def456       680 MB  [==]   │
│         ~/.../DerivedData/SwiftUI-Demo-def456   │
│                                                 │
│  ☐ 🟢  OldProject-ghi789         520 MB  [==]   │
│         ~/.../DerivedData/OldProject-ghi789     │
│                                                 │
│  ...                                            │
└─────────────────────────────────────────────────┘
```

Componentes SwiftUI: `List` con `Section`, filas custom (`HStack` + `Toggle` + `Text` + `SizeBar`).

### 5.4 Vista de contenedor con estrategias (AVDs / Simulators)

Esta es la pantalla **más importante** del producto, porque estos son los containers con más GB y más matices. **Aquí es donde SwiftUI nativo no alcanza** y necesitamos un componente custom.

```
┌─────────────────────────────────────────────────┐
│  Simuladores iOS · 5 devices · 4.9 GB           │
│                                                 │
│  ┌─── iPhone 15 Pro · iOS 17.4 · 2.1 GB ────┐  │
│  │  [■■■■■■■■■■■■■■■■■■■■□□□□□□□] breakdown │  │
│  │   userdata 1.7 GB   caches 250 MB   otros│  │
│  │                                           │  │
│  │  [Limpiar 🟢]  [Resetear 🟡]  [Eliminar 🟡]│  │
│  │                                           │  │
│  │  "Limpiar" borra 280 MB de caches y      │  │
│  │  snapshots. Las apps instaladas quedan.  │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ┌─── iPad Air · iOS 17.4 · 1.3 GB ──────────┐  │
│  │  ...                                       │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  Acción global:                                 │
│  [ Borrar huérfanos (xcrun simctl) 🟢 650 MB ] │
└─────────────────────────────────────────────────┘
```

**Componente custom:** `ContainerCard`. Al seleccionar una acción, la card cambia su estado visual (subrayado / color del borde) para reflejar qué se va a ejecutar. Solo una acción activa por container.

### 5.5 Confirmación de limpieza (dry-run)

Modal `.confirmationDialog` NO es suficiente — necesitamos lista completa. Usamos `.sheet`.

```
┌─────────────────────────────────────────────────┐
│  Revisar limpieza                               │
│                                                 │
│  Vas a liberar  12.7 GB  en 23 operaciones:     │
│                                                 │
│  XCODE                                          │
│  • DerivedData · 4 proyectos     3.1 GB  🟢    │
│  • CoreSimulator/Caches          2.4 GB  🟢    │
│  • iPhone 15 Pro (reset)         1.7 GB  🟡    │
│  • Archives · 2 builds           1.2 GB  🟡    │
│                                                 │
│  ANDROID                                        │
│  • system-images/android-30      2.8 GB  🟡    │
│  • Gradle caches                  0.9 GB  🟢    │
│  • Pixel_7_Pro (reset)            0.6 GB  🟡    │
│                                                 │
│  ⚠ Operaciones 🟡 (4):                         │
│    Implican re-descargas o pérdida de estado    │
│    de simuladores. ¿Continuar?                  │
│                                                 │
│          [ Cancelar ]    [ Limpiar 12.7 GB ]    │
└─────────────────────────────────────────────────┘
```

### 5.6 Progreso de limpieza

`ProgressView` con log en vivo en `DisclosureGroup`. Botón **Cancelar** siempre disponible.

### 5.7 Resultados

```
┌─────────────────────────────────────────────────┐
│  ✓ Limpieza completa                            │
│                                                 │
│         Liberaste  12.7 GB                      │
│                                                 │
│  23 operaciones exitosas                        │
│  0 errores                                      │
│                                                 │
│  [ Ver log completo ]  [ Listo ]                │
└─────────────────────────────────────────────────┘
```

Si hay errores: lista colapsable con ítem fallido + razón + comando que se intentó.

---

## 6. Componentes reutilizables

### 6.1 Nativos que usamos directo

| Componente | Uso |
|---|---|
| `NavigationSplitView` | Layout principal (sidebar + content + inspector). |
| `List` + `Section` | Listas de candidatos por categoría. |
| `DisclosureGroup` | Agrupaciones colapsables (ej. logs, detalles). |
| `Toggle` | Checkboxes de selección. |
| `Button` | Acciones. |
| `ProgressView` | Escaneo y limpieza. |
| `ContentUnavailableView` | Estado vacío, primera vez, error de permisos. |
| `Inspector` | Panel derecho con detalles del ítem seleccionado. |
| `Table` | Si queremos vista tabular con columnas (alternativa a List para categorías densas). |
| `Chart` (Swift Charts) | Opcional: dashboard con gráficos históricos. |

### 6.2 Componentes custom (pocos, enfocados)

```swift
/// Badge circular de riesgo. Verde o amarillo.
struct RiskBadge: View {
    let risk: RiskLevel
    var body: some View {
        Circle()
            .fill(risk == .green ? .green : .yellow)
            .frame(width: 8, height: 8)
            .accessibilityLabel(risk == .green ? "Basura directa" : "Basura opcional")
    }
}

/// Barra proporcional de tamaño relativo dentro de un grupo.
struct SizeBar: View {
    let size: Int64
    let maxSize: Int64
    var body: some View { ... }
}

/// Barra segmentada por componente (userdata + caches + otros).
struct BreakdownBar: View {
    let components: [InternalComponent]
    var body: some View { ... }
}

/// Tarjeta de container con 3 botones de estrategia.
struct ContainerCard: View {
    let container: ContainerCandidate
    @Binding var selectedAction: ContainerAction?
    var body: some View { ... }
}
```

### 6.3 Íconos

SF Symbols exclusivamente:
- Xcode → `hammer` o `hammer.fill`
- Android → `ant` (ligeramente humorístico) o ícono custom si queremos ser fieles.
- Simulador iOS → `iphone`
- AVD → `smartphone` (o custom)
- Gradle → `shippingbox.fill`
- SDK → `square.stack.3d.down.right`
- Caché → `tray.full.fill`
- Limpiar → `trash`
- Resetear → `arrow.counterclockwise`
- Escanear → `magnifyingglass`

---

## 7. Scanners — diseño interno

### 7.1 Interfaz común

```swift
protocol Scanner {
    var tool: Tool { get }
    func scan() async throws -> ToolReport
    func availableActions(for candidate: CleanupCandidate) -> [ExecutionStrategy]
}
```

### 7.2 XcodeScanner

Ejecuta en paralelo (con `TaskGroup`):
1. Tamaño de cada path estático en §3.1 / §3.3 del doc de rutas.
2. Enumeración y parseo de `xcrun simctl list devices --json` para simuladores.
3. Enumeración de `Archives/` agrupada por bundle ID + fecha.
4. Versiones de `iOS DeviceSupport` (heurística: versiones fuera del top 2-3 más recientes como 🟡).

### 7.3 AndroidScanner

1. Lectura de `~/.gradle/` con las reglas de §4.1.
2. Detección de versión activa de Gradle leyendo `gradle-wrapper.properties` en proyectos recientes.
3. Enumeración de AVDs via `emulator -list-avds` (o parse directo de `~/.android/avd/*.ini`) y lectura de `config.ini` de cada uno para mapear system-images.
4. Enumeración del SDK root con clasificación por categoría.
5. Detección de versiones huérfanas de Android Studio parseando sufijos de carpetas en `~/Library/Caches/Google/AndroidStudio*`, etc.

### 7.4 Cálculo de tamaño recursivo

```swift
actor SizeCalculator {
    private var cache: [URL: Int64] = [:]

    func size(of url: URL) async throws -> Int64 {
        if let cached = cache[url] { return cached }
        let total = try await recursiveSize(url)
        cache[url] = total
        return total
    }

    private func recursiveSize(_ url: URL) async throws -> Int64 {
        // Uses FileManager.enumerator with .totalFileAllocatedSizeKey
        // Parallelizable per top-level child
    }
}
```

**Truco:** `.totalFileAllocatedSizeKey` da el espacio real en disco (APFS), no el tamaño lógico. Es lo que el usuario espera ver liberarse.

---

## 8. Invocación de CLI externos

```swift
struct ProcessRunner {
    static func run(
        executable: URL,
        args: [String],
        timeout: TimeInterval = 30
    ) async throws -> ProcessResult { ... }
}

struct ProcessResult {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}
```

Requerimientos:
- Timeout por default (algunas CLI pueden colgarse).
- stdout/stderr capturados siempre.
- Cancelación propaga `SIGTERM` al proceso hijo.
- Path resolution via `/usr/bin/xcrun -f <tool>` para encontrar ejecutables.

Comandos esperados:
- `xcrun simctl list devices --json`
- `xcrun simctl delete unavailable`
- `xcrun simctl delete <UUID>`
- `xcrun simctl erase <UUID>` o `erase all`
- `xcrun simctl runtime delete unavailable`
- `xcrun simctl --set previews delete all`
- `~/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager list avd`
- `~/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager delete avd -n <name>`
- `~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --list_installed`
- `~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --uninstall <package>`

---

## 9. Permisos

**Decisión: no sandbox.** La app vive fuera del Mac App Store, se distribuye como DMG firmado + notarizado, con Developer ID.

**Justificación:**
- Acceder a `/Library/Developer/CoreSimulator/Profiles/Runtimes/` requiere escalada de privilegios en sandbox.
- Leer/escribir en `~/Library/Developer` requiere permisos que TCC maneja de forma menos amigable dentro del sandbox.
- Invocar `xcrun`, `avdmanager`, `sdkmanager` es más limpio sin sandbox.

**Permiso requerido en runtime:** Full Disk Access. Se detecta intentando leer `~/Library/Developer/Xcode/` — si falla con EACCES, se dirige al usuario al onboarding (§5.1).

---

## 10. Performance

### 10.1 Escaneo paralelo
- `TaskGroup` a dos niveles: top-level (Xcode vs Android corren en paralelo) y dentro de cada scanner, cada path principal se explora en su propia task.
- Actor dedicado para el `SizeCalculator` (evita condiciones de carrera).
- Target: **escaneo completo < 5 segundos** en Mac con ~50 GB de dev junk, SSD típico.

### 10.2 UI no bloqueante
- Toda operación de filesystem es `async`.
- Resultados se publican incrementalmente: las categorías aparecen en el Dashboard conforme se completan, no al final.

### 10.3 Cancelación
- Todos los `Task` son cancelables. Botón "Cancelar" en toolbar durante scan/clean.

---

## 11. Edge cases y manejo de errores

| Caso | Comportamiento |
|---|---|
| Xcode no instalado | Sección Xcode se oculta del sidebar. Dashboard solo muestra Android. |
| Android Studio no instalado | Igual para Android. |
| Ambos ausentes | Empty state: "No detectamos herramientas de desarrollo." Link a instalar. |
| Path esperado no existe | Se omite silenciosamente (no es error, solo ausencia). |
| CLI externo no responde (timeout) | Log entry, categoría marcada como "parcial", resto continúa. |
| Permiso denegado durante scan | Onboarding de permisos. |
| Borrado falla (archivo en uso) | Item marcado como error, log detallado, resto continúa. El total final refleja lo efectivamente liberado. |
| Xcode o Android Studio abierto durante cleanup | Warning previo: "Se recomienda cerrar Xcode antes de continuar." No es bloqueante. |

---

## 12. Accesibilidad

- Todos los botones y toggles tienen `accessibilityLabel`.
- Contraste respeta WCAG AA — verdes/amarillos no son el único canal (siempre acompañados de texto "🟢 Basura directa" / "🟡 Basura opcional").
- Navegación completa por teclado: Tab, flechas, Space, Enter.
- VoiceOver probado en las pantallas críticas (Dashboard, Container Card, Dry-run).

---

## 13. Decisiones abiertas y roadmap

### 13.1 Pendientes de v1

- **Distribución:** DMG directo desde landing? Homebrew cask? Sparkle para auto-update?
- **Telemetría:** recomiendo **ninguna** por default (coherente con principios de privacy). Si se agrega opcional, opt-in explícito.
- **Historial de limpiezas:** ¿se guarda log persistente? ¿con qué retención?

### 13.2 Confirmado para v2 (fuera de v1)

**Soporte a Flutter y React Native.** Las herramientas cross-platform tienen sus propios árboles de basura, muchas veces tan pesados como los nativos. Inventario seed para cuando arranquemos v2:

*Flutter / Dart*
- `~/.pub-cache/` — caché de paquetes Dart/Flutter. Suele ser 1–3 GB.
- `~/.flutter/` — config y snapshots del SDK.
- Flutter SDK root (path variable según instalación): `bin/cache/`, `bin/cache/artifacts/`, `bin/cache/dart-sdk/`.
- Proyectos: `build/`, `.dart_tool/`.

*React Native / Metro*
- `~/Library/Caches/com.meta.react-native-packager-cache-*` — Metro bundler cache.
- `/tmp/metro-*` y `/tmp/haste-map-*` — cachés temporales de Metro.
- `~/.expo/` — caché de Expo si el usuario lo usa.

*Package managers (transversal a ambos)*
- `~/.npm/_cacache/` — npm.
- `~/.yarn/cache/` — Yarn v1.
- `~/Library/Caches/Yarn/v6/` — Yarn moderno.
- `~/.pnpm-store/` — pnpm.

*Watchman*
- `/usr/local/var/run/watchman/` — cachés y clock files de watchman.

**Otras features v2**
- **Menu bar extra:** ícono en la barra para trigger rápido sin abrir la app.
- **Programación de limpiezas:** scheduler opcional (mensual por default).
- **Cross-platform Android** (Linux/Windows) — las rutas ya están documentadas en §6 del doc de rutas maestras.

---

## 14. Orden sugerido de implementación

| Fase | Entregable |
|---|---|
| 1 | Scanners headless (sin UI) — testeable por consola con salida JSON. |
| 2 | Modelo de dominio + ViewModels (sin UI). |
| 3 | Dashboard + SectionView con datos reales, sin acciones de cleanup. |
| 4 | Onboarding de permisos. |
| 5 | ContainerCard + acciones de cleanup para Simulators (el patrón más complejo). |
| 6 | Replicar pattern para AVDs. |
| 7 | Dry-run + ejecución. |
| 8 | Progreso + resultados. |
| 9 | Pulido: accesibilidad, modo oscuro, animaciones de transición. |
| 10 | Firma + notarización + DMG. |

---

*Documento vivo. Se ajusta según decisiones de implementación y feedback del usuario real.*
