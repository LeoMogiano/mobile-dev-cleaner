# ADR 006: Diseño (zip) vs motor (CLI mdc)

## Estado
Aceptado.

## Contexto
El handoff de diseño trae datos de ejemplo con algunas rutas y niveles de riesgo que no
coinciden con lo que el CLI `mdc` escanea de verdad.

## Decisión
- **Zip manda** en: UX, copy, flujos, agrupación, niveles de riesgo visibles
  (DeviceSupport y Previews = se regenera; versiones viejas de Studio = tiene costo;
  imágenes de sistema usadas por emuladores se muestran como costo en su propio grupo;
  breakdown de simuladores con Datos/Caché/Snapshots).
- **Node manda** en: rutas y comandos reales (runtimes en
  `/Library/Developer/CoreSimulator/Profiles/Runtimes`, Kotlin en `~/.kotlin/daemon`,
  residuos de test en `~/Library/Developer/XCTestDevices`).
- Nuevo respecto a Node: mover a la Papelera por defecto (`FileManager.trashItem`).
- Unidades: decimales con formato local ("18,2 GB"), como el diseño.
- Plan JSON exportado con el formato del prototipo `{tool, version, createdAt, ops[]}`.

## Consecuencias
- Totales pueden diferir del CLI por unidades (1000 vs 1024); se compara con tolerancia.
