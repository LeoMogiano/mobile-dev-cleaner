# Mobile Dev Cleaner

App nativa de macOS (SwiftUI, macOS 14+, Liquid Glass en 26+) que escanea y limpia lo
que dejan Xcode y Android Studio: DerivedData, cachés de Gradle, simuladores, AVDs, SDKs
viejos. Porta el motor del CLI `mdc` (`~/Workspace/Node/mobi-dev-clean`) con la UI del
handoff de diseño en `docs/design/handoff/`.

Promesa: **"Recupera espacio sin romper nada."** Debe sentirse como Ajustes del Sistema
› Almacenamiento, no como un "cleaner" agresivo. Sin dark patterns, sin alarmas rojas.

## Fuentes de verdad

| Tema | Fuente |
|---|---|
| UX, copy, riesgo, flujos, medidas | `docs/design/handoff/Mobile Dev Cleaner.dc.html` (código fuente, no capturas) + `README.md` |
| Paths y comandos reales | `~/Workspace/Node/mobi-dev-clean/src/scanners/*`, `cleaner.ts` |

Si zip y Node difieren: zip manda en UX/riesgo/copy, Node en paths/comandos. Ver
`docs/adr/006-design-vs-engine.md`.

## Idioma del código

- **Identificadores en inglés**.
- **Comentarios en inglés, mínimos y prolijos**: solo para un porqué no obvio. Nada que repita el código, sin bloques largos.
- **Tests en inglés**: nombres de `@Suite`/`@Test`, mensajes de `Issue.record`.
- **Strings de UI en español** en el código (clave base del String Catalog); inglés en
  `Localizable.xcstrings`. Fuera de SwiftUI: `L10n.string(...)`.

## Arquitectura: Clean Architecture por feature (estándar MyMicro)

```
MobileDevCleaner/
├── App/                    @main, RootView, Navigation/
├── Core/
│   ├── DI/                 ServiceLocator (`sl`), Injection, CoreModule
│   ├── Errors/ Functional/ Failure, Either
│   ├── Localization/       L10n, AppLanguage
│   ├── Platform/           ProcessRunner, SizeCalculator, TrashService, ProcessProbe, PathProvider…
│   ├── Formatting/         ByteFormatter
│   └── DesignSystem/       Tokens, Typography, Materials, Components/MDC*
└── Features/<Feature>/
    ├── <Feature>Module.swift          registro en el ServiceLocator
    ├── Domain/{Entities, Repositories, UseCases}
    ├── Data/{DataSources, Models, Repositories}
    └── Presentation/{<Screen>View, <Screen>ViewModel, Components/}
```

**Regla de capas**: Presentation → Domain ← Data. Domain solo importa Foundation.

- Entidades: `struct` `Equatable` + `Sendable` (+ `Identifiable` con id estable).
- Repositorios: `protocol X: Sendable`, métodos `async -> Either<Failure, T>`; impl `actor XRepositoryImpl`.
- DataSources: protocolo + `Impl` en el mismo archivo, `async throws`; el repo mapea con
  `Either.catching(domain:)`.
- UseCases: `struct XUseCase: Sendable` con `callAsFunction`, devuelven `Either`.
- ViewModels: `@MainActor @Observable final class`, propiedades `private(set)` planas
  (sin `state` anidado), `enum Status`, `enum <Screen>Intent` + `handle(_:)`, `result.fold`.
- DI: `sl.registerLazySingleton/Factory`, resolver con `sl()`. Orden en `Injection.setup()`:
  Core → features; dentro de cada módulo: data sources → repos → use cases.

## Vistas

- Una vista por archivo, **≤150 líneas** (tolerancia 170). Si crece, extraer componente.
- Reutilizable en 2+ features → `Core/DesignSystem/Components/` (prefijo `MDC`). Solo de
  un feature → `Features/<F>/Presentation/Components/`.
- Componentes reciben `let` + closures, nunca el ViewModel.
- Liquid Glass: `if #available(macOS 26, *), material == .liquidGlass { … } else { … }`.
- Íconos: SF Symbols reales (tabla en `docs/design/handoff/README.md`), no los SVG.
- Fuente: SF Pro para UI, SF Mono para rutas, Montserrat solo en momentos expresivos.

## Performance (requisito, gate por fase)

| Métrica | Objetivo |
|---|---|
| Escaneo en frío (~50 GB) | < 5 s, primeras categorías < 1 s |
| Re-escaneo con caché | < 1 s |
| Main thread | sin hangs > 100 ms |
| Memoria pico | < 150 MB |

- Nada de I/O ni `Process` en main. Walker de tamaño nativo (`getattrlistbulk`), nunca `du` por carpeta.
- TaskGroup acotado, cancelable (`Task.checkCancellation`).
- Publicación incremental con lotes (~100 ms) hacia la UI.
- Formateadores cacheados; `List`/`Lazy*` con ids estables; estado `@Observable` granular.
- `OSSignposter` en scan/size/cleanup.

## Seguridad (nunca negociable)

- Nunca escanear ni mostrar: keystores, certificados, provisioning profiles, claves ADB,
  licencias, `platform-tools`, `cmdline-tools`, `licenses`, runtimes en uso, backups.
- Nada se borra sin revisión. Papelera por defecto. Bloquear limpieza si Xcode, Android
  Studio, Simulator o un emulador están abiertos.
- Los tests **nunca** tocan rutas reales del usuario: todo vía `PathProvider` con home temporal.

## Build y tests

```
xcodegen generate
xcodebuild -project MobileDevCleaner.xcodeproj -scheme MobileDevCleaner \
  -destination 'platform=macOS' -derivedDataPath build/dd test
```

Traducciones: tras compilar, `scripts/sync_strings.py --missing` pasa las claves extraídas a
`Localizable.xcstrings` (xcodebuild no lo hace) y lista las que faltan en inglés.

Swift Testing (no XCTest). Mocks como `actor` que devuelven `Either`. Tests espejo de
`Features/` y `Core/`.

## Commits

Ramas `main` + `develop` (trabajo en `develop`, merge `--no-ff` a `main` en hitos).
Conventional commits `type(scope): subject`: subject en inglés imperativo minúscula, body
en español explicando el porqué. Sin líneas de coautoría.
