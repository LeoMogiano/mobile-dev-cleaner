# ADR 001: Clean Architecture por feature

## Estado
Aceptado. Adoptado del estándar de MyMicro / EGX Staff.

## Contexto
La app tiene un motor (scanners, medición de tamaño, ejecución de limpieza) y una UI
grande. Hay que poder probar el motor sin UI y la UI sin tocar el disco real.

## Decisión
Cada feature tiene `Domain/` (entidades, protocolos de repositorio, casos de uso),
`Data/` (data sources, implementaciones) y `Presentation/` (vistas y ViewModels).
Lo compartido vive en `Core/`. Presentation → Domain ← Data. ViewModels con estado
plano `private(set)` y `enum Status`.

## Consecuencias
- Los scanners son data sources: se prueban con un home temporal.
- Los ViewModels se prueban con repositorios mock (`actor`).
- Más archivos que una app monolítica; compensa por la paralelización entre agentes.
