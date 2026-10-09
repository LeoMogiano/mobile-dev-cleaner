# ADR 004: Either<Failure, T> en repositorios y casos de uso

## Estado
Aceptado. Igual que MyMicro.

## Decisión
Data sources usan `async throws`. Repositorios y casos de uso devuelven
`Either<Failure, T>`; el error original nunca llega a Presentation. `Failure.message`
ya viene localizado.

## Consecuencias
- Los errores de dominio (sin permiso, CLI ausente, archivo en uso) son explícitos.
- Los ViewModels consumen con `fold`.
