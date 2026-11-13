# AGENTS.md — OneStepConverter (macOS)

## 1. Visión del Proyecto
**OneStepConverter** es una aplicación nativa de macOS (código abierto / uso personal) diseñada para unificar y automatizar en un solo paso un flujo de trabajo de normalización y compresión de lotes de video.

### Problema que resuelve
Anteriormente, el procesamiento de lotes de video requería tres herramientas distintas:
1. **Smart Converter:** Para convertir archivos incompatibles (`.avi`, `.mkv`, etc.) a `.mp4` compatible ("tipo Android" / H.264 + AAC).
2. **Video Compressor:** Para reducir drásticamente el peso de los archivos, lo cual generaba contenedores `.mov`.
3. **Atajos / FFmpeg CLI:** Un script en terminal (`ffmpeg -i input.mov -c copy output.mp4`) para re-empaquetar los `.mov` de vuelta a `.mp4` universal sin recomprimir.

**OneStepConverter** reemplaza todo ese flujo ejecutando inspección, normalización, compresión por hardware/software y limpieza automática hacia la Papelera de macOS en una sola pasada directa a `.mp4`.

---

## 2. Stack Tecnológico y Entorno
- **Plataforma:** macOS 14.0+ (Sonoma / Sequoia / Tahoe) — optimizado para Apple Silicon (M-series).
- **Lenguaje & UI:** Swift 6 + SwiftUI nativo (sin dependencias de frameworks web).
- **Arquitectura de Concurrencia:** Swift Concurrency (`async/await`, `Actors`, `@Observable`).
- **Motor Multimedia:**
  - `ffprobe` y `ffmpeg` (binarios ubicados en `/opt/homebrew/bin/` o `/usr/local/bin/`, con soporte opcional para empaquetarlos dentro de `Contents/Resources/` para distribución en GitHub).
  - Aceleración de hardware mediante Apple `VideoToolbox` (`h264_videotoolbox` / `hevc_videotoolbox`) o `libx264` según perfil de compresión.
- **Integraciones Nativas macOS:**
  - `AppKit` (`NSOpenPanel`) para selección nativa de carpetas y archivos.
  - `UniformTypeIdentifiers` (`UTType.movie`, `UTType.fileURL`) para Drag & Drop nativo.
  - `FileManager.default.trashItem(at:resultingItemURL:)` para enviar originales a la Papelera de forma segura.
  - `UserNotifications` (`UNUserNotificationCenter`) para notificaciones nativas al completar cada archivo y al finalizar el lote.

---

## 3. Reglas de Negocio y Pipeline de Procesamiento

Cuando el usuario arrastra archivos o selecciona una carpeta, la aplicación debe ejecutar el siguiente pipeline por cada video detectado (escaneo recursivo opcional, ignorando archivos ocultos `.DS_Store` y temporales `*_temp.mp4`):

### Paso 1: Inspección (`ffprobe`)
Obtener metadatos en JSON (`ffprobe -v quiet -print_format json -show_format -show_streams`):
- Contenedor actual (extensión).
- Códec de video (`h264`, `hevc`, `mpeg4`, `msmpeg4v3`, etc.), resolución, framerate y bitrate.
- Códec de audio (`aac`, `mp3`, `ac3`, etc.).
- Duración total en segundos (necesaria para calcular el porcentaje de progreso exacto).

### Paso 2: Normalización + Compresión Directa a `.mp4`
En lugar de convertir a `.mp4` $
ightarrow$ comprimir a `.mov` $
ightarrow$ remuxear a `.mp4`, realizar la conversión y compresión en **una sola pasada**:
- **Compatibilidad Universal ("Tipo Android"):** Contenedor `.mp4`, perfil de video `H.264` (`yuv420p` para compatibilidad total en cualquier dispositivo/reproductor), audio `AAC` (`128k`, `44.1kHz`/`48kHz`) y flag `-movflags +faststart`.
- **Archivo Temporal:** Escribir siempre en `<nombre_original>_onestep_temp.mp4` en el mismo directorio de origen.
- **Comando Base FFmpeg (Modo Equilibrado / Alta Compresión):**
  ```bash
  ffmpeg -y -i "<input>" \
    -c:v libx264 -preset medium -crf 26 -pix_fmt yuv420p \
    -c:a aac -b:a 128k \
    -movflags +faststart \
    -progress pipe:1 -nostats \
    "<output_temp.mp4>"
  ```
  *(Nota para el agente: Se puede ofrecer alternancia con `-c:v h264_videotoolbox -b:v <target_bitrate>` para máxima velocidad por hardware en Apple Silicon, manteniendo `libx264 -crf 26` como estándar cuando se prioriza el menor tamaño de archivo posible).*

### Paso 3: Validación e Integridad
Antes de tocar el archivo original:
1. Verificar que `ffmpeg` terminó con `terminationStatus == 0`.
2. Verificar con `ffprobe` que `<output_temp.mp4>` existe, tiene tamaño `> 0` bytes, contiene stream de video válido y su duración coincide con el original (tolerancia `±1.5s`).

### Paso 4: Reemplazo y Papelera
1. Mover el archivo original a la Papelera de macOS usando `FileManager.default.trashItem(at: originalURL, resultingItemURL: nil)`.
2. Renombrar `<output_temp.mp4>` a `<nombre_original>.mp4`.
3. Si el original ya se llamaba `video.mp4`, primero se envía `video.mp4` a la papelera y acto seguido se renombra `video_onestep_temp.mp4` a `video.mp4`.

### Paso 5: Notificaciones
- Enviar notificación nativa discreta por cada video finalizado o al completar todo el lote (configurable).

---

## 4. Sistema de Diseño y Especificaciones UI (Basado en Figma)

La interfaz sigue una estética **Dark Mode espacial / neón púrpura translúcido** con ventana única de dimensiones fijas recomendadas: `760 x 560 pt` (con barra de título integrada `hiddenTitleBar` / `unifiedCompact` mostrando `OneStepConverter`).

### Paleta de Colores & Materiales
- **Fondo Principal:** Degradado radial/lineal profundo de Azul Medianoche a Negro Espacial (`#0F1736` en zona superior hacia `#050814` en zona inferior).
- **Acento Principal (Glow / Progreso):** Púrpura vibrante (`#7C3AED` a `#8B5CF6`) con resplandor exterior (`shadow(color: Color(hex: "#7C3AED").opacity(0.55), radius: 24)`).
- **Superficie Glass / Botones Secundarios:** Púrpura oscuro translúcido (`#1E2246` al 75% de opacidad) con borde sutil blanco al 15% (`1px`).
- **Tipografía:** SF Pro Display / SF Pro Rounded (Nativa macOS), color blanco puro (`#FFFFFF`) para títulos y gris azulado (`#94A3B8`) para metadatos.

### Estados de la Interfaz (3 Vistas Principales)

#### Vista 1: Inicio / Dropzone (`Inicio.png`)
- **Título Superior:** `ARRASTRA TUS VÍDEOS AQUÍ` (Bold, Uppercase, Tracking amplio, `30pt`).
- **Elemento Central:** Botón/Orbe circular Liquid Glass (`222 x 222 pt`) con `.ultraThinMaterial`, tinte glass `#3B3486` (12%), borde reflectivo a -45° y resplandor neón pulsante continuo en bucle. En su interior: ícono oficial `UploadArrow` (132x132 pt).
- **Zona Activa de Drag & Drop:** Rectángulo delimitado de `~460 x 260 pt` centrado alrededor del orbe. Arrastrar dentro activa el estado `.draggingOver` (`IconoAgregando`).
- **Acción Secundaria:** Botón tipo cápsula (`SELECCIONAR CARPETA`) debajo del orbe, con fondo `#1F2951`, esquinas redondeadas (`14pt`) y apertura de `NSOpenPanel` con advertencia de límite de 40 videos.

#### Vista 1.5: Confirmación y Configuración del Lote (`ConfirmarCompresion_2.png`)
- **Orbe Central:** Escala a `180 x 180 pt` con Liquid Glass y resplandor neón pulsante, mostrando el número de videos agregados en grande (`44pt`, Bold) y subtítulo `Videos Agregados` (`13pt`, `#94A3B8`). Toda el área central mantiene activo el receptor de Drag & Drop para seguir sumando videos hasta 40.
- **Fila Horizontal de Opciones de Configuración:**
  1. `Comprimir`: Switch estilo píldora con acento púrpura neón (`#8B5CF6`), encendido por defecto.
  2. `Modo privado`: Switch estilo píldora con acento púrpura neón (`#8B5CF6`), encendido por defecto. Al activarse, los nombres reales de los videos se enmascaran como "Video 1", "Video 2", etc. durante la conversión.
  3. `Formato`: Selector en cápsula blanca (`#FFFFFF`) con texto oscuro `#000320` y menú desplegable limpio (`MP4`, `MOV`, `MP3`). MP4 por defecto.
- **Botonera de Acción:**
  - Botón izquierdo `CANCELAR`: Cápsula roja oscura (`#7F0909`, `150 x 43 pt`) con resplandor sutil rojizo y texto blanco Bold. Vacía la cola, restablece opciones por defecto y regresa a la vista inicial.
  - Botón derecho: Cápsula púrpura (`#1F2951`, `240 x 43 pt`) con borde brillante. Muestra dinámicamente `COMPRIMIR Y CONVERTIR` cuando la compresión está activa, o `CONVERTIR` cuando `shouldCompress == false`.
- **Límite Estricto de 40 Videos:**
  - Si el usuario arrastra o selecciona un lote que haga superar 40 videos en total, **se rechaza el lote entrante por completo**.
  - El título cambia a `MÁXIMO 40 VIDEOS`.
  - El orbe y su resplandor neón cambian a rojo neón `#EF4444`.
  - Un temporizador cancelable de **6 segundos** restaura automáticamente la vista al estado previo.
- **Reglas de Ingesta:** Escaneo recursivo de extensiones válidas (`.mp4`, `.mov`, `.avi`, `.mkv`, `.m4v`, `.webm`, `.flv`, `.wmv`), archivos corruptos se descartan silenciosamente y se permiten archivos duplicados.

#### Vista 2: Procesando / Cola de Conversión (`Convirtiendo.png`)
- **Título Superior:** `CONVIRTIENDO` (Bold, Uppercase, `24pt`).
- **Lista de Videos (ScrollView limpio con efecto fade-out inferior):**
  Cada fila contiene:
  - **Ícono circular izquierdo (`44 x 44 pt`):** Estilo orbe púrpura con resplandor activo e ícono de cámara de video (`video.fill`). Los elementos en espera se muestran atenuados (opacidad ~30%).
  - **Título del archivo:** Nombre del video (`15pt`, Semibold, Blanco).
  - **Subtítulo de metadatos:** Formato y peso original + tiempo estimado + estado actual (ej. `MP4 - 1.2GB  |  Restan 2 minutos  -  Comprimiendo` o `Convirtiendo`).
  - **Botón cancelar individual:** Círculo oscuro derecho (`28 x 28 pt`) con ícono `xmark` para cancelar/omitir ese archivo.
  - **Barra de progreso individual:** Línea delgada (`4pt` de alto, puntas redondeadas) debajo de cada item, track oscuro (`#1E2246`) y relleno púrpura neón (`#8B5CF6`).
- **Footer de Progreso Global:**
  - Contador central: `2 de 10 videos` (`18pt`, Bold).
  - Subtexto de tiempo restante total: `20 minutos restantes` (`13pt`, `#94A3B8`).
  - Barra de progreso global en el borde inferior de la ventana (`6pt` de alto).

#### Vista 3: Proceso Completado (`ConversionCompletada.png`)
- **Título Superior:** `PROCESO COMPLETADO` (Bold, Uppercase, `22pt`).
- **Elemento Central:** Orbe circular púrpura (`180 x 180 pt`) con resplandor exterior e ícono de verificación (`checkmark`) blanco de trazo grueso.
- **Acción Principal:** Botón tipo cápsula (`CONVERTIR MÁS VÍDEOS`) que reinicia la cola y regresa a la Vista 1.

---

## 5. Arquitectura de Carpetas Sugerida (Xcode / SwiftUI)

```text
OneStepConverter/
├── AGENTS.md
├── App/
│   ├── OneStepConverterApp.swift       # Punto de entrada, configuración de ventana (760x560)
│   └── AppDelegate.swift               # Permisos de UNUserNotificationCenter
├── Core/
│   ├── Models/
│   │   ├── VideoItem.swift             # Modelo del archivo (URL, formato, tamaño, estado, progreso, ETA)
│   │   └── ConversionProfile.swift     # Perfiles (Equilibrado CRF 26, Máxima Compresión, Solo MP4)
│   ├── Services/
│   │   ├── FFmpegLocator.swift         # Busca ffmpeg/ffprobe en Bundle, /opt/homebrew/bin y /usr/local/bin
│   │   ├── VideoInspector.swift        # Wrapper async de ffprobe (duración, códecs, bitrate)
│   │   ├── VideoProcessor.swift        # Ejecución de Process, parsing de stdout/stderr para % y ETA
│   │   └── FileTrashManager.swift      # Validación post-proceso y envío seguro a Papelera
│   └── ViewModels/
│       └── QueueViewModel.swift        # Actor/Observable que gestiona la cola secuencial o concurrente
├── UI/
│   ├── Theme/
│   │   └── AppTheme.swift              # Gradientes, colores hex, modificadores de brillo (Glow)
│   ├── Components/
│   │   ├── GlowingOrbView.swift        # Orbe púrpura reutilizable (Upload, Video Icon, Checkmark)
│   │   ├── NeonProgressBar.swift       # Barra de progreso redondeada púrpura
│   │   └── VideoRowView.swift          # Fila de video en la vista Convirtiendo
│   └── Views/
│       ├── MainContainerView.swift     # Orquestador de estados (Inicio -> Convirtiendo -> Completado)
│       ├── DropzoneView.swift          # Vista 1 (Inicio.png)
│       ├── ConvertingView.swift        # Vista 2 (Convirtiendo.png)
│       └── CompletedView.swift         # Vista 3 (ConversionCompletada.png)
└── Resources/
    └── Assets.xcassets                 # AppIcon (Logo.png)
```

---

## 6. Directrices de Desarrollo para Agentes (Antigravity / AI)

1. **Seguridad de Archivos Ante Todo:** Jamás eliminar un archivo original con `FileManager.removeItem`. Usar exclusivamente `FileManager.default.trashItem` y **únicamente** después de confirmar que el `.mp4` de salida existe y es legible por `ffprobe`.
2. **Sandbox / Permisos macOS:** Para una app distribuida fuera de la App Store (GitHub), desactivar App Sandbox (`ENABLE_APP_SANDBOX = NO`) en el target de Xcode permite ejecutar libremente `/opt/homebrew/bin/ffmpeg` y mover archivos a la papelera sin restricciones de Security-Scoped Bookmarks.
3. **Cálculo de Progreso Real:** No usar barras indeterminadas. Usar `-progress pipe:1` en `ffmpeg`, leer `out_time_us` (microsegundos procesados) y dividir entre la duración total obtenida previamente con `ffprobe` para obtener un `Double` exacto de `0.0` a `1.0` y calcular el ETA real.
4. **Fidelidad Visual:** Respetar estrictamente los diseños de referencia (`Inicio.png`, `Convirtiendo.png`, `ConversionCompletada.png`) y la estética del ícono (`Logo.png`).
5. **Manejo de Errores:** Si un video está corrupto o `ffmpeg` falla, marcar ese `VideoItem` con estado `.failed(reason)` sin detener el resto de la cola ni borrar el archivo original.
