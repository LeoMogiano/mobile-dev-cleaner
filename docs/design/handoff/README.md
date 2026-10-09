# Handoff: Mobile Dev Cleaner — app de escritorio macOS

## Overview
Mobile Dev Cleaner escanea y limpia lo que dejan Xcode y Android Studio (DerivedData, cachés de Gradle, simuladores, AVDs, SDKs viejos…). La UX gira en torno a tres conceptos, siempre con ícono + texto (nunca solo color):
- **Se regenera solo** (verde) — cachés/builds que Xcode o Gradle recrean al compilar.
- **Tiene costo** (naranja) — no rompe nada, pero implica re-descargas o pérdida de datos de simulador.
- **Nunca lo tocamos** — keystores, certificados, perfiles, llaves ADB. No se escanean ni se muestran en la UI principal (solo se mencionan en el onboarding).

Debe sentirse como una app de Apple (Ajustes del Sistema / Almacenamiento), no como un "cleaner" agresivo. Sin dark patterns, sin alarmas rojas.

## About the Design Files
Los archivos de esta carpeta son **referencias de diseño hechas en HTML**: un prototipo interactivo que muestra el aspecto y comportamiento deseados, **no código de producción**. La tarea es **recrearlo en el entorno real del proyecto**. Recomendación: **SwiftUI nativo (macOS 14+/26 Tahoe)** con `NavigationSplitView`, `Settings` scene, `.sheet`, SF Symbols y materiales del sistema (`.regularMaterial` / Liquid Glass en Tahoe). Si el proyecto ya usa otra tecnología (p. ej. Tauri/Electron + React), seguir sus patrones.

Para ver el prototipo: abrir `Mobile Dev Cleaner.dc.html` en un navegador (requiere `support.js` y `mdc-icon.js` en la misma carpeta). El panel de Tweaks del prototipo expone props: `theme` (light/dark), `material` (tahoe/classic), `start` (onboarding/dashboard/scanning/clean/noPermission), `appsOpen` (estado bloqueado), `errors` (resultado con errores), `starStyle` (fondo del ícono de estrella: azul por defecto).

## Fidelity
**High-fidelity.** Colores, tipografía, espaciados, copy y flujos son finales. Recrear con fidelidad usando componentes nativos equivalentes. Íconos: el prototipo usa íconos SVG que imitan SF Symbols; en nativo usar los **SF Symbols reales** (tabla en Assets).

## Ventana y layout
- Ventana por defecto **1100×720**, mínima 900×600. Toolbar unificada con traffic lights nativos.
- **Tres columnas**: Sidebar 262 px · Contenido flexible · Inspector "Detalles" 248 px (**solo visible cuando hay un elemento seleccionado**, con botón × para cerrarlo).
- Material **Liquid Glass (Tahoe)** por defecto: ventana translúcida radio 22, sidebar flotante (margen 8, radio 16, borde blanco 0.5 px). Opción **Clásico** (Sonoma/Sequoia): ventana opaca radio 12, sidebar pegada.
- Contenido: padding 22/24 px, `max-width` 820–860 centrado.

## Screens / Views

### 1. Onboarding (ventana 740×560 centrada, sin sidebar)
Pie: puntos de progreso a la izquierda (activo 18 px ancho, inactivo 7 px, alto 7), a la derecha "Atrás" (texto) + secundario + primario (alto 30, pill).
1. **Bienvenida** — grid 2 columnas (texto | tarjeta 290 px). Izquierda: ícono app 40 px + wordmark Montserrat 700 15; título Montserrat 700 **36 px**, tracking −0.04em: "Recupera espacio sin romper nada."; subtítulo SF 14 t2: "Encuentra lo que Xcode y Android Studio dejan atrás y te explica qué es antes de borrarlo." Derecha: tarjeta de ejemplo rotada 1.5° ("En la Mac de un dev mobile", 37,7 GB en Montserrat 34, barra verde/naranja, 4 filas: Builds de Xcode 6,1 GB ↻, Cachés de Gradle 7,4 GB ↻, Simuladores iOS 3,8 GB ⏱, Keystores y certificados 🔒 —). Botón: **Comenzar**.
2. **Cómo funciona** — título Montserrat 28 "Cómo funciona", sub "Todo lo que encontramos cae en una de estas tres cajas." Tres tarjetas (ícono 36 en tile tintado + título 14/600 + una frase):
   - Se regenera solo — "Casi todo se regenera solo cuando compilas."
   - Tiene costo — "Lo que tiene costo, te lo explicamos antes."
   - Nunca lo tocamos — "Lo delicado ni siquiera lo escaneamos."
3. **Acceso total al disco** — ícono disco 64 con badge escudo azul; título Montserrat 26 "Permite el acceso total al disco"; texto honesto (solo leemos tamaños). Tarjeta de **4 pasos numerados** (filas 36 px): Abre Ajustes del Sistema › Privacidad y seguridad › Acceso total al disco › Activa Mobile Dev Cleaner [switch que se enciende al conceder]. Botones: **Ahora no** / **Abrir Ajustes del Sistema** → estado "Esperando permiso…" con spinner → "✓ Acceso concedido" → primario cambia a **Continuar**.
4. **Notificaciones** — ícono campana (tile rojo). Título: "¿Te avisamos cuando termine la limpieza?" Texto: "Así puedes seguir trabajando mientras limpiamos. Una sola notificación al terminar, con lo que liberaste. Nada más." Ejemplo de notificación: "Limpieza completada · Liberaste 18,2 GB. Parte volverá a crecer al compilar." Botones: **No, gracias** / **Permitir notificaciones**. ⚠ Las notificaciones son **solo** para "limpieza completada" — no hay recordatorios por umbral.
5. **Listo** — escudo verde, "Todo listo.", "Todo ocurre en tu Mac. Sin telemetría, sin internet. Nada se borra sin que lo revises antes." Botón **Escanear mi Mac** → dashboard en estado escaneando.

### 2. Sidebar
- Traffic lights + wordmark (ícono 24 gradiente azul→violeta con papelera + "Mobile Dev Cleaner" Montserrat 700 13.5).
- **Resumen**.
- Secciones **Xcode** / **Android** (título 11/700 t3 + total a la derecha). Filas 28 px: ícono SF 15 en accent, nombre humano, tamaño 11 px t3 tabular. Selección: fondo accent, texto blanco.
- **Solo se muestran categorías ≥ 1 GB**; las pequeñas se agrupan en una fila "N más pequeñas" (chevron) que expande/colapsa. Categorías vacías ocultas por defecto (toggle en Ajustes).
- Sección **Flutter**: fila "Proyectos Flutter" con badge **Pronto** (futuro: build/, .dart_tool, caché de pub).
- Pie: **Historial**. (No hay "Lo que nunca tocamos" en la sidebar.)
- Sin puntos de color en las filas (se quitaron por ruido).

### 3. Toolbar (alto 52)
Título (15/700, nowrap, ellipsis) · botón icono ↻ (tooltip "Escanear de nuevo (⌘R)") · **buscador blanco** (150×28, mismo borde/sombra que botones, SF Pro 13, placeholder "Buscar", tooltip ⌘F) · botón engranaje (Ajustes ⌘,). Todos los botones `white-space: nowrap`. No hay filtro segmentado.

### 4. Resumen / Dashboard
- **Hero** (tarjeta radio 16, padding 22/24): "Puedes recuperar" 13/500 t2 → número **Montserrat 700 60 px**, tracking −0.045em, + unidad 26 px; **cuenta hacia arriba** (ease-out cúbico, 1.1 s) al terminar el escaneo. Barra segmentada 12 px (verde = se regenera / naranja = tiene costo, gap 2) + leyenda con tamaños.
- **Limpieza recomendada**: tile ↻ verde 38, título 15/600, "**18,2 GB** que Xcode y Gradle regeneran solos cuando los necesites.", botón primario **Limpiar 18,2 GB**. Lista interna top 3 categorías + "y N más". Nota 11.5 t3: "↻ Esto volverá a crecer a medida que compiles. Es normal." Clic en el botón = marca todo lo regenerable (excepto carpetas excluidas) y abre la hoja de revisión.
- **Requiere tu decisión**: tile ⏱ naranja, subtítulo "Tiene costo. Revísalo uno por uno."; filas 36 px: ícono · nombre · tamaño de la parte con costo · chevron → navega a la categoría.
- Pie 11 t3: "Último escaneo: hace 2 min · Última limpieza: 12 sep, liberaste 21,0 GB".
- Estados: **Escaneando** (spinner + % + ruta actual mono + barras de progreso Xcode/Android + filas que aparecen una a una con skeleton), **Todo limpio** (círculo verde 96 con check, "Tu Mac está ordenada." Montserrat 28, "No hay nada que limpiar ahora mismo. Vuelve después de unas semanas de builds.", botón Escanear de nuevo), **Sin permisos** (banner naranja de una línea "Algunas carpetas no se pudieron medir." + Dar acceso + ×).

### 5. Vista de categoría (lista)
- Cabecera: tile 46 (color de herramienta) + nombre 22/700 + nombre técnico mono 11 t3 + tamaño 22/600 + RiskBadge(s).
- Explicador colapsable **cerrado por defecto**: "¿Qué es y qué pasa si lo borro?" → 3 columnas: ¿Qué es? / ¿Qué pasa si lo borro? / ¿Vuelve a aparecer?
- Fila de acciones: "N elementos · M marcados" + **Marcar todo** (⌘A) / **Ninguno**.
- Grupos con encabezado (p. ej. Caché compartido · Tus proyectos · Proyectos que ya no existen [etiqueta "Huérfano: seguro de borrar"]) + tamaño del grupo.
- Fila 34 px: checkbox 15 · nombre (flex) · [ruta mono solo si "nombres técnicos" está activo] · RiskBadge (**solo si la categoría mezcla tipos**) · barra de tamaño 90×4 · tamaño 58 px derecha · botón "Mostrar en Finder". Clic en fila = abre inspector. Elementos excluidos con opacidad 0.5.
- Inspector: nombre, badge, Ruta completa (mono), Tamaño, Última modificación, Por qué aparece, Qué pasa si lo borro, ¿Vuelve a aparecer?, [Comando si está activo], botones Mostrar en Finder / Marcar.

### 6. Simuladores iOS / Emuladores Android (contenedores)
Grid `auto-fill minmax(300px,1fr)`. Tarjeta: ícono dispositivo 38 · nombre 14/600 · SO · tamaño · badge **En uso** (si corre). Barra de desglose 7 px (Datos de apps = accent, Caché = naranja, Snapshots = morado) + leyenda. **Control segmentado** sin selección por defecto: **Limpiar** (verde, "Libera X") / **Restablecer** (naranja) / **Eliminar** (naranja); descripción debajo: "Borra la caché. Tus apps y datos quedan." / "Como recién creado. Se pierden apps y datos." / "Borra el dispositivo completo." (este último en rojo). Si está en uso: opacidad 0.5, deshabilitado, tooltip "Ciérralo para poder limpiarlo". Tarjeta con acción elegida: anillo accent 1.5 px.

### 7. Barra de selección (flotante, abajo-centro del contenido)
"N seleccionados · X GB" · Deseleccionar (texto accent) · **Revisar y limpiar** (primario, ⌫).

### 8. Hojas (sheets) — estilo macOS
Bajan desde la toolbar (top 58, ancho 520, radio 22 Tahoe / 12 Clásico), fondo casi opaco con blur, sombra `0 0 0 .5px rgba(0,0,0,.18), 0 18px 50px rgba(0,0,0,.22)`, overlay `rgba(0,0,0,.1)`. Botones con `min-width: 88`, Cancelar a la izquierda del primario. Entrada: 280 ms `cubic-bezier(.2,.9,.3,1.05)` desde translateY(−10) scale(.985).
- **Revisar y limpiar**: ícono app 44 + "Vas a liberar 8,2 GB" (17/700) + "N elementos". Grupo "↻ Se regenera solo · N elementos · X GB" (filas agregadas por categoría) y grupo "⏱ Tiene costo · …" (una fila por elemento con su costo concreto, p. ej. "Gradle 8.4: se volverá a descargar la próxima vez que abras un proyecto que la use (~180 MB)"). [Comandos si está activo.] Checkbox **Mover a la Papelera (puedes recuperarlos)** (refleja ajuste). Si hay costo y la confirmación extra está activa: checkbox "Entiendo que algunos se volverán a descargar o perderán datos" y el primario dice **Entiendo, limpiar** (deshabilitado hasta marcar). Si no: **Limpiar**.
- **Bloqueada**: "Cierra estas apps primero" + lista (Xcode, Simulator, Android Studio, Emulador) con estado "Abierta"; botones **Cancelar** / **Volver a comprobar** (spinner "Comprobando…"). Sin botón de limpiar.
- **Progreso**: anillo 104 px (trazo 7, accent) con %, "Limpiando…", GB liberados en vivo 24/700 + "de X GB", "i de n · elemento actual" t3. Pie: "Si cancelas, lo que ya se limpió queda limpio." + Cancelar.
- **Resultado**: check verde 64 animado (pop 560 ms), "**Liberaste 18,2 GB**" Montserrat 700 30, mensaje educativo ↻ en caja verde tenue, "Está en la Papelera. El espacio se libera al vaciarla." (si aplica), errores colapsables "3 no se pudieron limpiar" con motivo + Mostrar en Finder. Botones **Ver historial** / **Listo**. Si las notificaciones están activas, además se muestra una notificación del sistema "Limpieza completada".
- **Acceso total al disco**: misma estructura que el paso 3 del onboarding.

### 9. Historial
Tarjeta resumen: "Espacio liberado en total" + Montserrat 40 ("84,0 GB") + "N limpiezas" + mini gráfico de barras verdes (una por limpieza) + nota "El espacio vuelve a crecer mientras desarrollas. Por eso conviene limpiar cada 2–4 semanas." Lista: fecha · N elementos · GB, expandible con desglose por categoría (barras).

### 10. Ajustes (ventana separada ⌘,, 620×640, fondo casi opaco)
Barra de pestañas con íconos (84 px c/u): **General · Apariencia · Avanzado · Acerca de**. Formularios agrupados estilo Ajustes del Sistema (tarjetas radio 10, filas con etiqueta izq / control der / descripción 11 t2). Switches 36×20 verdes.
- **General**: Herramientas (Xcode, Android, Flutter "Próximamente"); Escanear al abrir; Mostrar categorías vacías; **Notificaciones**: "Avisarme cuando termine la limpieza"; Carpetas excluidas (lista + botones +/−); **Seguridad**: Mover a la Papelera (on), Pedir confirmación extra para elementos con costo (on, "Recomendado"), No limpiar si Xcode/Android Studio/emulador abiertos (on, bloqueado con candado); Permisos (Acceso total al disco ✓ Concedido / ⚠ No concedido + Dar acceso; Notificaciones switch).
- **Apariencia**: miniaturas Claro / Oscuro / Automático; Material segmentado "Liquid Glass (Tahoe)" / "Clásico"; Idioma (Español / English).
- **Avanzado**: Mostrar nombres técnicos y rutas completas; Mostrar comandos que se ejecutarán; Caché de tamaños (2,3 MB) + Vaciar; Plan de limpieza JSON Importar/Exportar (compatible con CLI `mdc`); **Integraciones (Próximamente)**: "Claude (servidor MCP)" + Avisarme, "Otros agentes y editores"; Mostrar el onboarding de nuevo; Restablecer todos los ajustes (rojo, con confirmación inline).
- **Acerca de**: Cabecera de la app (ícono 56, "Mobile Dev Cleaner" Montserrat 17, "Versión 1.0.2 · Licencia MIT · Sin telemetría"); grupo: **Dale una estrella en GitHub** (tile azul de sistema con estrella blanca → github.com/LeoMogiano/mdc-cli) y **Reportar un problema** (→ /issues). Sección **Creador**: fila perfil (avatar LM 44 con gradiente, "Leo Mogiano" Montserrat 600 14, "AI Mobile Dev Enthusiast · Hice esta app porque mi Mac se quedaba sin espacio cada semana."), GitHub (tile #1b1f24, github.com/LeoMogiano), LinkedIn (tile #0a66c2, linkedin.com/in/leomogiano), Invítame un café (tile amarillo #ffe24a→#ffcc00, buymeacoffee.com/leomogiano). Todas las filas de enlace: 44 px, tile 26 radio 7, etiqueta, valor t3, chevron.

## Interactions & Behavior
- Atajos: ⌘R re-escanear, ⌘F buscar, ␣ marcar, ⌘A marcar todo, ⌫ revisar y limpiar, ⌘, ajustes, ⌘1/⌘2 Xcode/Android, Esc cierra hojas/Ajustes.
- Fricción proporcional: solo regenerable → confirmación simple; con costo → checkbox "Entiendo"; apps abiertas → bloqueo.
- Nada está marcado por defecto en las vistas de detalle; la Limpieza recomendada marca solo lo regenerable.
- Transiciones 160–300 ms; respetar "Reducir movimiento" (sin count-up ni pop).
- Al terminar: los elementos limpiados desaparecen, los simuladores "limpiados" pierden caché/snapshots, "restablecidos" pierden datos, "eliminados" desaparecen; se añade entrada al historial.
- Formato local: "18,2 GB" (es) / "18.2 GB" (en). Tamaños < 1 GB en MB.

## State Management
`screen` (onboarding/main), `obStep`, `fda` + `fdaState` (idle/wait/ok), `notif`, `view` (dashboard/history/<categoryId>), `inspect` (id), `scan` (0–1), `count` (0–1 animación hero), `sel` {itemId:true}, `act` {deviceId:'clean'|'reset'|'delete'}, `q`, `sheet` (review/progress/result/fda), `understand`, `appsOpen`, `prog`, `ops`, `done`, `errs`, `history`, `settings` {xcode, android, scanOnOpen, showEmpty(false), excluded[], trash(true), confirmCost(true), blockOpen(true, fijo), showTech, showCmds, lang}, `theme` (light/dark/auto), `material` (tahoe/classic). Datos reales vendrán del motor del CLI `mdc` (escaneo de ~/Library/Developer, ~/.gradle, ~/.android, ~/Library/Android/sdk).

## Design Tokens
| Token | Claro | Oscuro |
|---|---|---|
| accent | #007AFF | #0A84FF |
| regenerates | #34C759 (texto #1A7F37, fondo rgba(52,199,89,.15)) | #30D158 (fondo rgba(48,209,88,.18)) |
| hasCost | #FF9F0A (texto #A35200, fondo rgba(255,159,10,.17)) | #FFB340 (fondo rgba(255,179,64,.18)) |
| protected | #8E8E93 | #98989D |
| destructive | #FF3B30 | #FF453A |
| snapshots | #AF52DE | #BF5AF2 |
| Xcode | #1575F9 | #1575F9 |
| Android | #2DB86B | #2FA66A |
| Flutter | #027DFD | — |
| label 1/2/3 | rgba(0,0,0,.86/.60/.44) | rgba(255,255,255,.92/.64/.44) |
| separator | rgba(0,0,0,.08) | rgba(255,255,255,.09) |
| card (Clásico) | #F5F5F7 | #2C2C2E |
| card (Tahoe) | rgba(255,255,255,.6) | rgba(255,255,255,.08) |
| ventana (Clásico) | #FFFFFF | #1E1E1E |

Ícono de app: `linear-gradient(135deg,#3aa0ff 0%,#5b6cff 55%,#a35bff 100%)`. Fondo de escritorio Tahoe claro: `linear-gradient(120deg,#9ec4ff,#c9b3ff 40%,#ffb3d9 70%,#ffd29e)`.

**Tipografía**: SF Pro (sistema) para toda la UI funcional — 13 base, 11–12 secundario, 15–17 títulos de sección, 22 cabecera de categoría. SF Mono para rutas/comandos (11). **Montserrat** solo en momentos expresivos: títulos de onboarding (26–36, 700), número héroe (60, 700, −0.045em), wordmark, "Liberaste X GB" (30), total del historial (40), nombre del creador (600).
**Radios**: controles 6 (Clásico) / pill (Tahoe); tarjetas 10–16; hojas 22/12; tiles de ícono 7–12. **Espaciado** base 8; contenido 22–24. **Separadores** 0.5 px.

## Assets — SF Symbols a usar en nativo
Resumen `square.grid.2x2` · Builds `hammer` · Cachés `tray` · Tests `checklist` · Simuladores `iphone` / `ipad` / `applewatch` · Runtimes `cube` · Soporte iPhones `iphone.and.arrow.forward` · Archives `archivebox` · Previews `eye` · CocoaPods/Gradle cachés `shippingbox` · Dependencias `square.stack.3d.up` · Versiones `square.on.square` · Logs `doc.text` · NDK `wrench.adjustable` · Studio viejo `clock` · Se regenera `arrow.triangle.2.circlepath` · Tiene costo `clock.arrow.circlepath` · Protegido `lock.fill` · Advertencia `exclamationmark.triangle` · Ajustes `gearshape` · Avanzado `slider.horizontal.3` · Apariencia `display` · Acerca de `info.circle` · Disco `internaldrive` · Escudo `checkmark.shield` · Campana `bell` · Historial `clock.arrow.circlepath` · Finder `arrow.up.forward.circle` · Estrella `star.fill` · Café `cup.and.saucer` · MCP `sparkles` / `powerplug` · Flutter `square.stack`. Logos de GitHub/LinkedIn: usar los oficiales de cada marca.

## Files
- `Mobile Dev Cleaner.dc.html` — prototipo completo (plantilla + lógica: datos de ejemplo, flujos, estados).
- `mdc-icon.js` — íconos SVG placeholder estilo SF Symbols (sustituir por SF Symbols).
- `support.js` — runtime necesario para abrir el prototipo en el navegador.

## Pendiente / futuro
- Versión en inglés (verificar que textos ~20 % más largos no rompan el layout).
- Limpieza de proyectos Flutter (build/, .dart_tool, ~/.pub-cache).
- Integración MCP con Claude y otros agentes.
