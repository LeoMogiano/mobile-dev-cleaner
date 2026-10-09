# ADR 005: XcodeGen como fuente del proyecto

## Estado
Aceptado.

## Contexto
MyMicro usa grupos sincronizados; este repo nació con XcodeGen (`project.yml`).

## Decisión
`project.yml` es la fuente de verdad; `MobileDevCleaner.xcodeproj` se regenera con
`xcodegen generate` tras agregar o quitar archivos. Solo el orquestador lo regenera
(los agentes trabajan sobre archivos ya creados como stub) para evitar carreras.

## Consecuencias
- Diffs del pbxproj reproducibles.
- Olvidar `xcodegen generate` = archivo nuevo fuera del target; el build lo delata.
