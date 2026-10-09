# ADR 002: Sin dependencias externas

## Estado
Aceptado.

## Decisión
Solo frameworks de Apple (SwiftUI, Foundation, UserNotifications, os). Nada de SPM.

## Consecuencias
- Binario universal pequeño, firma y notarización simples.
- DI, Either y medición de tamaño se escriben a mano (son pocos cientos de líneas).
