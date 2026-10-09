# Prompt para Claude Design — Mobile Dev Cleaner (app de escritorio macOS)

> Copia todo este documento en Claude Design. Describe el producto, el sistema visual, la UX y cada pantalla a diseñar.

---

## 0. Punto de partida: iterar sobre el prototipo existente

Ya existe un prototipo hecho en Claude Design (`Mobile Dev Cleaner.zip`: React + CSS, con frame de ventana macOS). **No partir de cero**: evolucionarlo.

**Conservar** (funciona bien):
- Layout de tres columnas: sidebar + contenido + inspector "Detalles".
- Estética **Liquid Glass Tahoe** (macOS 26): fondo de escritorio con gradiente, ventana y sidebar translúcidas. Es el estilo por defecto, con la opción "Clásico" (Sonoma/Sequoia) en Ajustes.
- Tokens claro/oscuro existentes (`--accent #0a84ff`, `--green #30d158`, `--yellow`, `--bg-card`, etc.).
- Hero del dashboard: "Se puede liberar hasta 18.0 GB", con barra Xcode/Android.
- Flujo con sheets: Dry-run → Progreso → Resultado.
- Datos del autor y botón "Buy Me a Coffee" (ver §7.3).

**Corregir y mejorar**:
- Botones de la toolbar que parten el texto en dos líneas ("Escanear de nuevo", "Limpiar seleccionados 6.6 GB") y tamaños que se parten ("3.1 / GB"). Usar `white-space: nowrap`, labels más cortos o solo ícono + tooltip, y anchos mínimos.
- La sidebar muestra nombres técnicos (DerivedData, AVDs, System images) y solo 7 categorías: usar nombres humanos y cubrir todas las categorías reales (§4).
- No existe el concepto de **"se regenera"**: es el cambio principal de esta iteración (§2, §5.3, §5.7).
- Onboarding de solo 2 pasos: ampliarlo (§5.1).
- Ajustes en una sola lista plana con tweaks de desarrollo (variante de ContainerCard): reorganizar en pestañas (§7) y fijar **una** variante de ContainerCard, la de control segmentado/radio con descripción de la acción elegida.
- Sin Montserrat: añadirla según §3.
- "Buy Me a Coffee" y "Permisos" sueltos al pie de la sidebar: moverlos a Ajustes. Al pie de la sidebar solo quedan "Lo que nunca tocamos" e "Historial".

---

## 1. Qué es el producto

**Mobile Dev Cleaner** es una app de escritorio para **macOS** que escanea y limpia la basura que dejan **Xcode** y **Android Studio**: builds (DerivedData), cachés de Gradle, simuladores iOS, emuladores Android (AVDs), SDKs viejos, runtimes, versiones huérfanas del IDE. Libera normalmente **20–40 GB** en la Mac de un dev mobile.

Hoy existe como app de terminal (TUI). Queremos la versión **desktop nativa estilo Apple**: se tiene que sentir como una app de Apple (Ajustes del Sistema, Almacenamiento de macOS, Xcode Organizer), no como un "Clean my Mac" agresivo.

**Usuario**: desarrollador iOS/Android/Flutter/React Native. Sabe qué es un build, pero no sabe qué carpetas de `~/Library` puede borrar sin romper nada.

### El mensaje central (lo más importante de la UX)

Esta app **no es un botón de "borrar todo"**. Ayuda a **entender** el espacio:

1. **Casi todo lo que limpia se regenera**: Xcode y Gradle lo vuelven a crear cuando compilas. Limpiar no es definitivo; es como vaciar una caché que vuelve a crecer.
2. **Algunas cosas tienen costo**: borrarlas no rompe nada, pero luego toca esperar re-descargas (SDKs, dependencias) o se pierden datos de un simulador.
3. **Hay cosas que nunca tocamos** (keystores, certificados, perfiles de provisión, llaves ADB, licencias, runtimes en uso). Mostrarlas genera confianza.

Toda la UI debe comunicar estos tres conceptos con lenguaje humano, sin asustar y sin jerga.

---

## 2. Principios de UX

1. **Fácil primero, detalle después**: la pantalla inicial resuelve el 80 % de los casos con un clic ("Limpieza recomendada" = solo lo que se regenera solo). El detalle por categoría está disponible, nunca impuesto.
2. **Nada marcado por defecto** en el modo detallado. En la limpieza recomendada, el usuario ve exactamente qué se incluye antes de confirmar.
3. **Explicar antes de borrar**: cada categoría responde tres preguntas: *¿Qué es? · ¿Qué pasa si lo borro? · ¿Vuelve a aparecer?*
4. **Fricción proporcional al riesgo**:
   - Solo "se regenera" → una confirmación simple.
   - Incluye "tiene costo" → hoja de advertencia que lista el costo concreto (ej. "Gradle volverá a descargar ~2,1 GB").
   - Apps abiertas (Xcode, Android Studio, Simulator, un AVD corriendo) → bloquea con un mensaje claro y un botón "Volver a comprobar".
5. **Mover a la Papelera** como opción segura (activada por defecto en Seguridad), para poder recuperar.
6. **Lenguaje humano**: "Builds de Xcode", no "DerivedData" (el nombre técnico va en gris, secundario).
7. **Sin dark patterns**: sin alarmas rojas, sin "¡Tu Mac está en peligro!", sin contadores inflados.
8. **Privacidad visible**: "Todo ocurre en tu Mac. Sin telemetría. Sin conexión a internet."

---

## 3. Sistema visual

### Tipografía

- **SF Pro** (fuente del sistema de Apple: `-apple-system`, `SF Pro Text` / `SF Pro Display`) para **toda la interfaz funcional**: listas, botones, sidebar, ajustes, tablas, cuerpo de texto. Tamaños de macOS: 13 pt base, 11 pt secundario, 15–17 pt para títulos de sección.
- **SF Mono** para rutas de archivo y comandos.
- **Montserrat** como toque estético de marca, **solo en momentos expresivos**:
  - Títulos grandes del onboarding (Montserrat SemiBold/Bold, 28–34 pt).
  - El **número héroe** de espacio recuperable en el dashboard ("32,4 GB"), en Montserrat Bold, 48–64 pt, con tracking ligeramente negativo.
  - El wordmark del nombre de la app.
  - El nombre en la sección "Acerca de mí".
  - La pantalla de resultado ("Liberaste 18,2 GB").
- Regla: si es algo que se **lee para operar**, va en SF Pro. Si es algo que se **siente** (marca, celebración, bienvenida), puede ir en Montserrat.

### Color (tokens, claro y oscuro)

Basado en los colores semánticos de macOS. Todo debe existir en **modo claro y modo oscuro**.

| Token | Uso | Claro | Oscuro |
|---|---|---|---|
| `accent` | botones primarios, selección | System Blue `#007AFF` | `#0A84FF` |
| `regenerates` | "Se regenera solo" (antes "verde") | `#34C759` | `#30D158` |
| `hasCost` | "Tiene costo" (antes "amarillo"; reemplaza el `#e8b500` del prototipo porque el ámbar contrasta mejor sobre vidrio claro) | `#FF9F0A` | `#FFB340` |
| `protected` | "Nunca lo tocamos" | `#8E8E93` + ícono de candado | `#98989D` |
| `destructive` | solo para el botón final "Eliminar" de un simulador | `#FF3B30` | `#FF453A` |
| `bg/window` | fondo de ventana | `#FFFFFF` / vibrancy | `#1E1E1E` / vibrancy |
| `bg/sidebar` | sidebar translúcida (material) | vibrancy claro | vibrancy oscuro |
| `bg/card` | tarjetas agrupadas | `#F5F5F7` | `#2C2C2E` |
| `label/primary·secondary·tertiary` | texto | etiquetas de sistema | etiquetas de sistema |

Colores de herramienta, usados con moderación (íconos y barras de breakdown):
- Xcode: azul `#1575F9`
- Android: verde Android `#3DDC84` (desaturado en oscuro)

### Forma, espaciado y materiales

- Radio de esquinas: 10 px en tarjetas, 6 px en controles, 14 px en sheets/modales.
- Espaciado base de 8 px. Márgenes de contenido de 20–24 px.
- Sidebar con **material translúcido (vibrancy)**, toolbar unificada con el título, **traffic lights** nativos.
- Sombras mínimas, como en macOS. Separadores de 0,5 px.
- Íconos: **SF Symbols** (`internaldrive`, `hammer`, `iphone`, `apps.iphone`, `shippingbox`, `arrow.triangle.2.circlepath` para "se regenera", `clock.arrow.circlepath` / `exclamationmark.triangle` para "tiene costo", `lock.fill` para "protegido", `trash`, `gearshape`, `person.crop.circle`).

### Movimiento

- Transiciones suaves de 200–300 ms con spring, al estilo de macOS.
- El número héroe **cuenta hacia arriba** al terminar el escaneo.
- Durante el escaneo, las categorías aparecen una a una con un skeleton shimmer sutil.
- Respetar "Reducir movimiento".

---

## 4. Arquitectura de la app

Ventana principal con **sidebar + contenido** (patrón de Ajustes del Sistema / Finder). Ventana mínima de 900×600, por defecto 1100×720.

**Sidebar:**

```
[Wordmark Mobile Dev Cleaner]

  Resumen                     ← dashboard (home)

XCODE                    12,4 GB
  Builds de Xcode
  Cachés y temporales
  Residuos de test
  Simuladores iOS
  Runtimes de simulador
  Soporte de iPhones
  Archives
  SwiftUI Previews
  CocoaPods · Carthage · Fastlane

ANDROID                  19,8 GB
  Cachés de Gradle
  Dependencias de Gradle
  Versiones de Gradle
  JDKs de Gradle
  Logs de Gradle · Kotlin
  Cachés de Android
  Emuladores Android
  Imágenes de sistema
  NDK / cmake / build-tools
  Versiones viejas de Studio

─────────
  Lo que nunca tocamos 🔒
  Historial
```

- Cada fila muestra un ícono, el nombre humano, el tamaño alineado a la derecha y un punto de color (verde/naranja) si contiene elementos de ese tipo.
- Las categorías vacías o no detectadas aparecen atenuadas con "No encontrado" (o se ocultan con un toggle en Ajustes).
- Si no hay Xcode o Android Studio instalado, esa sección completa se colapsa con un mensaje amable.

**Toolbar:** botón "Escanear de nuevo" (↻), campo de búsqueda, filtro segmentado [Todo | Se regenera | Tiene costo], y a la derecha la **barra de selección** ("3 elementos · 8,2 GB · [Revisar y limpiar]").

**Ajustes** en una ventana separada (⌘,) con pestañas tipo macOS: **Escaneo · Seguridad · Ajustes · Avanzado** (ver §7).

---

## 5. Pantallas a diseñar

Diseñar cada pantalla en **modo claro y en modo oscuro**.

### 5.1 Onboarding (primer arranque)

Estilo "Bienvenido a…" de Apple: ventana centrada sin sidebar, de 3–4 pasos con indicador de puntos, botón primario abajo a la derecha y "Atrás" secundario.

1. **Bienvenida**: ícono de la app grande y título en Montserrat: *"Recupera espacio sin romper nada."* Subtítulo en SF Pro: "Mobile Dev Cleaner encuentra lo que Xcode y Android Studio dejan atrás y te explica qué es antes de borrarlo." Botón: **Comenzar**.
2. **Cómo funciona**: tres tarjetas horizontales con ícono:
   - 🔄 **Se regenera solo**: "Cachés y builds. Xcode o Gradle los vuelven a crear cuando compilas. Limpiarlos es seguro, pero volverán a crecer."
   - ⏱ **Tiene costo**: "No rompe nada, pero después toca esperar re-descargas o se pierden datos de un simulador. Te avisamos siempre."
   - 🔒 **Nunca lo tocamos**: "Certificados, keystores, perfiles de provisión, llaves ADB. Ni siquiera aparecen en la lista."
3. **Permiso: Acceso total al disco** (modal/sheet de permiso, ver §6.1).
4. **Permiso: Notificaciones** (opcional, ver §6.2).
5. **Listo**: "Todo ocurre en tu Mac. Sin telemetría, sin internet." Botón: **Escanear mi Mac**, que lleva al dashboard con el escaneo en curso.

### 5.2 Dashboard / Resumen (home)

Responde de un vistazo: *¿cuánto puedo liberar y qué es seguro?*

- **Héroe**: "Puedes recuperar" + **32,4 GB** (Montserrat, grande) + una barra horizontal segmentada (estilo Almacenamiento de macOS) que divide el total en *Se regenera* (verde) / *Tiene costo* (naranja), con leyenda.
- **Tarjeta primaria: Limpieza recomendada**:
  - "**18,2 GB** que Xcode y Gradle regeneran solos cuando los necesites."
  - Lista colapsable de lo que incluye (top 5 + "y 7 más").
  - Botón primario: **Limpiar 18,2 GB**.
  - Nota pequeña: "↻ Esto volverá a crecer a medida que compiles. Es normal."
- **Dos tarjetas lado a lado: Xcode | Android**: tamaño total, mini breakdown de las 3 categorías más grandes y botón "Ver detalle" que salta a la sidebar.
- **Tarjeta secundaria: Requiere tu decisión**: lo que tiene costo (simuladores, runtimes, SDKs, Studio viejo), con el texto "Revísalo uno por uno" y un link a cada categoría.
- **Pie**: "Último escaneo: hace 2 min · Última limpieza: 12 sep, liberaste 21 GB".

Estados a diseñar: **escaneando** (skeleton + progreso por herramienta), **resultado**, **todo limpio** (ilustración tranquila: "Tu Mac está ordenada. Vuelve después de unas semanas de builds."), **sin permisos** (banner, ver §6.1).

### 5.3 Vista de categoría (lista de archivos)

Ejemplo: "Builds de Xcode".

- **Cabecera**: ícono, nombre humano grande, nombre técnico en gris (`DerivedData · ~/Library/Developer/Xcode/DerivedData`), tamaño total y un badge de riesgo.
- **Tarjeta explicativa** (colapsable, abierta la primera vez):
  - **¿Qué es?** "Archivos intermedios que Xcode genera al compilar cada proyecto."
  - **¿Qué pasa si lo borro?** "El próximo build de ese proyecto tardará más (compila desde cero)."
  - **¿Vuelve a aparecer?** "Sí. Xcode lo regenera en cuanto compilas. ↻"
- **Lista agrupada** (estilo tabla de macOS, filas de 28–32 px):
  - Grupos con encabezado, por ejemplo: *Caché compartido · Tus proyectos · Proyectos que ya no existen*. Este último lleva una etiqueta sutil "Huérfano: seguro de borrar".
  - Cada fila: checkbox, nombre, ruta truncada en SF Mono gris, badge de riesgo, barra de tamaño relativo y tamaño.
  - Hover: botón "Mostrar en Finder" (ícono de flecha).
  - Clic en una fila: abre un **inspector lateral** (panel derecho tipo Xcode/Finder) con la ruta completa, la razón, la última modificación y "Qué pasa si lo borro".
- **Barra inferior fija** cuando hay selección: "4 seleccionados · 6,1 GB" + **Revisar y limpiar**.
- Atajos visibles en tooltips (␣ marcar, ⌘A todo, ⌘F buscar, ⌫ limpiar).

### 5.4 Vista de contenedores (Simuladores iOS / Emuladores Android)

Son distintos: no se marcan con checkbox, se elige una **acción por dispositivo**.

- Grid o lista de tarjetas por dispositivo: ícono del dispositivo (iPhone/iPad/Watch/Pixel), nombre, versión del SO y tamaño total.
- **Barra de breakdown** dentro de la tarjeta: *Datos de apps* / *Caché* / *Snapshots*, con leyenda.
- **Control segmentado** de acción, nada elegido por defecto:
  - **Limpiar** (verde): "Borra la caché. Tus apps y datos quedan."
  - **Restablecer** (naranja): "Como recién creado. Se pierden apps y datos."
  - **Eliminar** (naranja, el texto de confirmación en rojo): "Borra el dispositivo completo."
- Cada opción muestra cuánto libera.
- Si el dispositivo está corriendo: badge "En uso" y acciones deshabilitadas con el tooltip "Ciérralo para poder limpiarlo".

### 5.5 Revisar y limpiar (sheet de confirmación)

Sheet modal que baja de la toolbar (estilo macOS).

- Título: "Vas a liberar **8,2 GB**".
- Lista agrupada por tipo: *Se regenera solo (6 elementos · 5,1 GB)* / *Tiene costo (2 elementos · 3,1 GB)*.
- Para lo que tiene costo, cada línea explica su costo concreto: "Gradle 8.4: se volverá a descargar la próxima vez que abras un proyecto que la use (~180 MB)".
- Opción visible: ☑ "Mover a la Papelera (puedes recuperarlos)", que refleja el ajuste de Seguridad.
- Botones: **Cancelar** / **Limpiar** (azul). Si hay elementos con costo, el botón dice **Entiendo, limpiar** y requiere marcar un checkbox "Entiendo que algunos se volverán a descargar".
- **Variante bloqueada**: "Cierra estas apps primero", con una lista de apps abiertas (íconos de Xcode, Simulator, Android Studio, emulador X), el botón **Volver a comprobar** y el botón **Cancelar**. Sin botón de limpiar.

### 5.6 Progreso

- Dentro de la misma sheet: anillo o barra de progreso, el contador de GB liberados en vivo y el elemento actual en gris.
- "Cancelar": "Lo que ya se limpió queda limpio."

### 5.7 Resultado

- Check animado y **"Liberaste 18,2 GB"** en Montserrat.
- Mensaje educativo: "↻ Parte de esto volverá a crecer mientras desarrollas. Es normal: así funcionan Xcode y Gradle. Te recomendamos revisar cada 2–4 semanas."
- Si hubo errores: lista colapsable "3 no se pudieron limpiar", con el motivo y "Mostrar en Finder".
- Botones: **Listo** / **Ver historial**.

### 5.8 Lo que nunca tocamos 🔒

Página informativa que genera confianza. Lista con candados:
- Keystores y certificados de firma
- Perfiles de provisión
- Llaves ADB y licencias de Android aceptadas
- Runtimes y simuladores en uso
- Backups de dispositivos
- Binarios críticos del SDK (`adb`, `platform-tools`, `cmdline-tools`)

Texto: "Estos archivos son difíciles o imposibles de recuperar. Por diseño, Mobile Dev Cleaner ni siquiera los escanea."

### 5.9 Historial

Lista cronológica de limpiezas: fecha, GB liberados, cantidad de elementos y un desglose expandible. Arriba, un mini gráfico de barras: "Espacio liberado en total: 84 GB". Ayuda a reforzar la idea de que el espacio vuelve a crecer y por eso se limpia periódicamente.

---

## 6. Modales de permisos (estilo Apple)

Sheets centradas, ícono grande arriba, título corto, explicación honesta y pasos visuales.

### 6.1 Acceso total al disco (necesario)

- Ícono: disco + escudo.
- Título: **"Permite el acceso total al disco"**.
- Texto: "Lo necesitamos para medir los runtimes de simulador y algunas carpetas de sistema. Solo leemos tamaños; nunca abrimos tus archivos ni enviamos nada fuera de tu Mac."
- Mini ilustración de 3 pasos: *Ajustes del Sistema → Privacidad y seguridad → Acceso total al disco → activar Mobile Dev Cleaner*.
- Botones: **Abrir Ajustes del Sistema** (primario) / **Ahora no**.
- Estado de espera: "Esperando permiso…" con un spinner, que cambia a ✓ automáticamente al detectarlo.
- Si se omite: el escaneo funciona parcialmente y aparece un **banner no intrusivo** en el dashboard y en "Runtimes de simulador": "Algunas carpetas no se pudieron medir. [Dar acceso]".

### 6.2 Notificaciones (opcional)

- Título: **"¿Te avisamos cuando haya mucho para limpiar?"**
- Texto: "Una notificación ocasional cuando superes el umbral que elijas (ej. 20 GB). Nada más."
- Botones: **Permitir notificaciones** / **No, gracias**.

---

## 7. Ajustes (ventana ⌘,)

Ventana de preferencias de macOS con pestañas de íconos arriba. Formularios agrupados (estilo Ajustes del Sistema de macOS Ventura+: filas en tarjetas redondeadas, etiqueta a la izquierda, control a la derecha, descripción gris debajo).

### 7.1 Escaneo
- **Herramientas a escanear**: toggles para Xcode / Android.
- **Escanear al abrir la app**: toggle.
- **Recordatorio**: "Avísame cuando haya más de [ 20 GB ▾ ] para limpiar" (requiere notificaciones) y "Revisar cada [ 2 semanas ▾ ]".
- **Carpetas excluidas**: lista + botón (+/−) para elegir carpetas o proyectos que nunca se marcarán (ej. el DerivedData de un proyecto en el que trabajas a diario).
- **Mostrar categorías vacías** en la sidebar: toggle.

### 7.2 Seguridad
- **Mover a la Papelera en vez de eliminar**: toggle, activado por defecto. Descripción: "Puedes recuperarlos desde la Papelera. El espacio se libera al vaciarla."
- **Pedir confirmación extra para elementos con costo**: toggle, activado y recomendado.
- **No limpiar si Xcode, Android Studio o un emulador están abiertos**: toggle, activado y bloqueado con candado e info: "Evita corromper builds en curso".
- **Permisos**: estado de "Acceso total al disco" (✓ Concedido / ⚠ No concedido + botón) y de Notificaciones.
- Link: "Ver lo que nunca tocamos 🔒".

### 7.3 Ajustes
- **Apariencia**: tres miniaturas seleccionables al estilo macOS: *Claro · Oscuro · Automático (sistema)*.
- **Material**: segmentado *Liquid Glass (Tahoe)* · *Clásico*, con miniatura de vista previa.
- **Idioma**: popup *Español / English*.
- **Acerca de mí**: tarjeta destacada dentro de esta pestaña (reutilizar `AboutSection` y `AboutSheet` del prototipo, con estilo pulido):
  - Avatar circular (iniciales "LM" sobre gradiente azul→violeta, o foto si se sube) y el nombre **Leo Mogiano** en Montserrat SemiBold.
  - Tagline: "AI Mobile Dev Enthusiast" (en el prototipo dice "IA Mobile Dev Entusiasth"; corregir la ortografía).
  - Bio corta en SF Pro (placeholder: "Hice esta app porque mi Mac se quedaba sin espacio cada semana.").
  - Botones-pastilla con íconos: **GitHub** (github.com/LeoMogiano) · **LinkedIn** (linkedin.com/in/leomogiano).
  - CTA **Buy Me a Coffee** (buymeacoffee.com/leomogiano): píldora amarilla de marca dentro de una tarjeta suave, con el texto "Si te ahorró espacio, invítame un café ☕".
  - Debajo, la info de la app: ícono pequeño, "Mobile Dev Cleaner · Versión 1.0.2", "Licencia MIT", "Sin telemetría · Sin internet", links "Reportar un problema" y "Ver en GitHub" (github.com/LeoMogiano/mdc-cli).

### 7.4 Avanzado
Opciones para usuarios avanzados, con un tono más técnico:
- **Mostrar nombres técnicos y rutas completas** en las listas (toggle; por defecto se muestran los nombres humanos).
- **Mostrar comandos que se ejecutarán** (ej. `xcrun simctl erase <UDID>`, `avdmanager delete avd`) en la sheet de confirmación (toggle).
- **Caché de tamaños**: "Hace que los re-escaneos sean casi instantáneos · 2,3 MB" + botón **Vaciar caché de tamaños**.
- **Exportar plan de limpieza (JSON)** / **Importar plan**: compatible con el CLI `mdc`.
- **Herramienta de línea de comandos**: estado "`mdc` instalado ✓ / no instalado" + botón "Copiar comando de instalación" (`npm install -g mobile-dev-cleaner`).
- **Mostrar el onboarding de nuevo**: botón.
- **Restablecer todos los ajustes**: botón en rojo con confirmación.

---

## 8. Componentes a definir en el sistema

- **RiskBadge**: pastilla con ícono + texto. Tres variantes: *Se regenera* (verde, ↻) · *Tiene costo* (naranja, ⏱) · *Protegido* (gris, 🔒). Siempre con ícono + texto, nunca solo color (accesibilidad).
- **SizeBar**: barra fina de tamaño relativo dentro de una fila.
- **BreakdownBar**: barra segmentada (almacenamiento / datos de simulador) con leyenda.
- **CategoryRow** (sidebar), **CandidateRow** (lista), **DeviceCard** (simulador/AVD con control segmentado).
- **ExplainerCard**: ¿Qué es? / ¿Qué pasa si lo borro? / ¿Vuelve a aparecer?
- **SelectionBar**: barra fija inferior con el total seleccionado y la CTA.
- **PermissionSheet**: plantilla para los modales de permisos.
- **Banner**: informativo (azul) / advertencia (naranja), descartable.
- **HeroNumber**: número grande en Montserrat con animación de conteo.
- **EmptyState**: ilustración lineal suave + texto + acción.

---

## 9. Copy y tono

- Tratamiento de **tú**, cercano y claro; nada de alarmismo.
- Bilingüe **es/en**: diseñar en español y verificar que el inglés no rompa el layout (textos ~20 % más largos).
- Vocabulario fijo:
  - "Se regenera solo" / *Regenerates on its own*
  - "Tiene costo" / *Has a cost*
  - "Nunca lo tocamos" / *Never touched*
  - "Limpiar" (acción general), "Restablecer" (simulador), "Eliminar" (dispositivo completo)
- Tamaños en formato local: "18,2 GB" (es) / "18.2 GB" (en).

---

## 10. Accesibilidad

- Contraste AA en ambos modos. El riesgo nunca se comunica solo con color.
- Navegación completa con teclado y foco visible (anillo de enfoque de macOS).
- Atajos: ⌘R re-escanear, ⌘F buscar, ␣ marcar, ⌘A marcar todo, ⌫ revisar y limpiar, ⌘, ajustes, ⌘1/⌘2 Xcode/Android.
- Soporte de "Reducir movimiento" y "Aumentar contraste".
- Etiquetas de VoiceOver en los badges y barras ("Builds de Xcode, 6,1 GB, se regenera solo").

---

## 11. Entregables esperados de Claude Design

1. Tokens de diseño (color claro/oscuro, tipografía SF Pro + Montserrat, espaciado, radios).
2. Librería de componentes (§8) con sus estados (default, hover, seleccionado, deshabilitado, foco).
3. Pantallas en **claro y oscuro**:
   - Onboarding (5 pasos, incluidos los 2 modales de permisos)
   - Dashboard (escaneando, resultado, todo limpio, sin permisos)
   - Vista de categoría con inspector
   - Simuladores/AVDs
   - Sheet de revisión (normal, con costo, bloqueada)
   - Progreso
   - Resultado (éxito, con errores)
   - Lo que nunca tocamos
   - Historial
   - Ajustes (Escaneo, Seguridad, Ajustes + Acerca de mí, Avanzado)
4. Un flujo prototipado: **Onboarding → Escaneo → Limpieza recomendada → Revisar → Progreso → Resultado**.

### Datos de ejemplo para los mockups

- Total recuperable: 32,4 GB (Se regenera: 18,2 GB · Tiene costo: 14,2 GB)
- Xcode 12,4 GB: Builds de Xcode 6,1 GB · Simuladores iOS 3,8 GB (iPhone 16 Pro iOS 18.2 1,9 GB; iPad Air iOS 17.5 1,2 GB; Apple Watch S10 0,7 GB) · Soporte de iPhones 1,6 GB · Cachés 0,9 GB
- Android 19,8 GB: Cachés de Gradle 7,4 GB · Dependencias de Gradle 4,9 GB · Imágenes de sistema 3,6 GB · Emuladores 2,8 GB (Pixel 8 API 34 2,1 GB) · Versiones viejas de Studio 1,1 GB
- Proyectos de ejemplo en Builds: `MyBankApp-abcd…`, `EGXOne-efgh…`, `old-prototype-ijkl…` (este último está huérfano: el proyecto ya no existe)
