# ADR 003: ServiceLocator estilo GetIt

## Estado
Aceptado. Igual que MyMicro.

## Decisión
`ServiceLocator` propio con `registerFactory`, `registerLazySingleton`,
`registerSingleton` y global `@MainActor let sl`. Composition root en
`Injection.setup()`; cada feature expone `<Feature>Module.register()`.

## Consecuencias
- Mismo patrón que los equipos Android/Flutter.
- Error de registro faltante = `fatalError` en arranque, se detecta rápido.
