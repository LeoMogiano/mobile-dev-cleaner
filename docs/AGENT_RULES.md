# Reglas para agentes implementadores (Mobile Dev Cleaner)

Repo: `/Users/leo_mogiano/Workspace/Swift/MobileDevCleaner`. Lee primero `CLAUDE.md` y
respétalo. Para SwiftUI consulta `.claude/skills/swiftui-specialist/SKILL.md` y sus
`references/`.

## Modo de reporte
Reporta en estilo caveman (frases cortas, sin relleno). El código, los comentarios y los
strings se escriben normal.

## Alcance
- Solo editas los archivos que tu tarea te asigna. Ya existen como stubs; llénalos.
- **NUNCA** edites `project.yml`, `project.pbxproj` ni archivos de otro agente.
- Si necesitas un archivo nuevo, **no lo crees**: repórtalo y el orquestador lo agrega.
  (Los tests en `MobileDevCleanerTests/` asignados a ti sí existen ya como stub.)
- **NO hagas commit.** No ejecutes `git` que modifique estado.
- Nunca borres ni muevas archivos reales del usuario. Tests solo en directorios temporales.

## Fuente de verdad del diseño (UI)
- `docs/design/handoff/Mobile Dev Cleaner.dc.html`: lee el **código fuente** (template +
  `style="..."` inline + `mkData()`), nunca capturas. 1 px CSS = 1 pt.
- `padding: a b c d` = top right bottom left.
- `box-shadow: 0 Ypx Bpx rgba(...)` → `.shadow(color:, radius: B/2, x: 0, y: Y)`.
- `letter-spacing: -0.04em` a 36 pt → `.tracking(-1.44)` (em × tamaño).
- Bordes redondeados: `.background(c, in: RoundedRectangle(cornerRadius: r, style: .continuous))`
  + `.overlay(RoundedRectangle(...).strokeBorder(c2, lineWidth: w))`. Nunca `.border()` + `.cornerRadius()`.
- Copy exacto del HTML (español). Íconos: SF Symbols de la tabla del README.
- Tokens en `Core/DesignSystem/` (no inventes colores si existe token).

## Swift
- Swift 6, `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`, concurrencia estricta: tipos
  `Sendable`, ViewModels `@MainActor @Observable`.
- Sin dependencias externas. Sin `AnyView`. `ForEach` con ids estables.
- Nada de I/O, `Process` ni parsing pesado en main.
- Botones de solo ícono llevan `.accessibilityLabel("...")` en español.

## Compilar (cada agente con su propio DerivedData)
```
cd /Users/leo_mogiano/Workspace/Swift/MobileDevCleaner && set -o pipefail && \
xcodebuild -project MobileDevCleaner.xcodeproj -scheme MobileDevCleaner \
  -destination 'platform=macOS' -derivedDataPath build/agent-<TU_ID> build-for-testing 2>&1 \
  | grep -E "error:|warning:.*MobileDevCleaner/|\*\* (BUILD|TEST)" | tail -30
```
Tests solo de tu suite:
```
xcodebuild ... -derivedDataPath build/agent-<TU_ID> test-without-building \
  -only-testing:MobileDevCleanerTests/<SuiteStructName>
```
Si aparece un error en un archivo FUERA de tu alcance, es de otro agente: ignóralo, espera
~1 min y recompila; repórtalo si persiste.

## Reporte final (caveman)
- Archivos tocados.
- Estado de build y de tus tests.
- Líneas por vista (`wc -l`).
- Medidas del HTML aplicadas (en tareas de UI).
- Dudas o archivos nuevos que necesitas.
