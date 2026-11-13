<p align="center">
  <img src="assets/logo.png" alt="OneStepConverter Logo" width="160" height="160" style="border-radius: 36px; box-shadow: 0 10px 30px rgba(124, 58, 237, 0.4);">
</p>

<h1 align="center">OneStepConverter</h1>

<p align="center">
  <strong>Normalización y compresión de lotes de video en un solo paso para macOS.</strong><br>
  Aplicación nativa, rápida y de código abierto construida con SwiftUI y aceleración de hardware para Apple Silicon.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue?style=flat-square&logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon-purple?style=flat-square" alt="Apple Silicon">
  <img src="https://img.shields.io/badge/Methodology-Spec--Driven%20Development-864AF9?style=flat-square" alt="Spec-Driven Development">
  <img src="https://img.shields.io/badge/License-Open%20Source-green?style=flat-square" alt="Open Source">
</p>

---

## 🎯 ¿Qué es OneStepConverter?

**OneStepConverter** es una herramienta de escritorio para macOS diseñada para eliminar la fricción al procesar grandes lotes de video.

### El problema que resuelve
Anteriormente, normalizar y comprimir videos requería hasta tres herramientas independientes:
1. **Smart Converter:** Para convertir archivos en formatos incompatibles (`.avi`, `.mkv`, etc.) a formato universal `.mp4` (H.264 + AAC).
2. **Video Compressor:** Para reducir drásticamente el peso de los archivos, generando contenedores intermedios `.mov`.
3. **Atajos / FFmpeg CLI:** Scripts de terminal (`ffmpeg -i input.mov -c copy output.mp4`) para re-empaquetar los videos de vuelta a `.mp4` sin perder tiempo recomprimiendo.

### La solución en un solo paso
**OneStepConverter** unifica todo este pipeline en una sola pasada directa:
- **Inspección automática (`ffprobe`):** Detección de códecs de video/audio, dimensiones, bitrate y duración exacta.
- **Control de Lote y Límite de 40 Videos:** Ingesta inteligente por arrastre o selector nativo de carpetas, con escaneo recursivo y validación de lote máximo de 40 videos con feedback visual de alerta.
- **Normalización + Compresión unificada:** Convierte cualquier formato a `.mp4` universal ("tipo Android": H.264 + AAC + `faststart`) con compresión balanceada por CPU (`libx264`) o acelerada por GPU (`VideoToolbox`).
- **Validación de integridad:** Comprobación estricta del resultado antes de interactuar con el archivo original.
- **Limpieza segura:** Envío automático del original a la Papelera de macOS mediante `FileManager.trashItem`.

---

## 📐 Metodología: Spec-Driven Development (SDD)

Este proyecto se desarrolla siguiendo de forma estricta la metodología **Spec-Driven Development (SDD)**:

> **El código nunca improvisa; el código implementa especificaciones.**

1. **Especificación previa:** Cada funcionalidad, pantalla o ajuste técnico se diseña primero en un documento de especificación formal (`specs/NN-nombre.md`) que delimita el alcance (*In / Out of scope*), modelo de datos, plan de ejecución paso a paso y criterios de aceptación booleanos.
2. **Validación y Aprobación:** Solo cuando la especificación ha sido revisada y marcada como aprobada, se inicia la implementación técnica.
3. **Control de Versiones Atómico:** Cada especificación se asocia a una rama de trabajo dedicada (`feat/...` o `fix/...`) garantizando trazabilidad y calidad de software continua.

---

## 🛠️ Stack Tecnológico

- **Plataforma:** macOS 14.0+ (Sonoma / Sequoia / versiones posteriores) optimizado para procesadores Apple Silicon (M-series).
- **Lenguaje & UI:** Swift 6 + SwiftUI nativo (sin dependencias web ni capas intermedias).
- **Concurrencia:** Swift Concurrency moderno (`async/await`, `Actors`, macro `@Observable`).
- **Motor Multimedia:** Integración con `ffmpeg` y `ffprobe` con aceleración de hardware vía Apple `VideoToolbox`.
- **Integraciones Nativas:**
  - `UniformTypeIdentifiers` para Drag & Drop fluido.
  - `AppKit` (`NSOpenPanel`) para selección de directorios y archivos.
  - `UserNotifications` para alertas nativas del sistema.

---

## 🎨 Sistema de Diseño

La interfaz cuenta con una estética **Dark Mode espacial** con acentos neón y materiales translúcidos:
- **Fondo:** Degradado radial y vertical continuo de Azul Medianoche a Negro Espacial (`#101639` $\rightarrow$ `#080D2D` $\rightarrow$ `#000320`).
- **Superficies Glass:** Acabado translúcido `#1F2951` con borde difuso del 15%.
- **Acento Neón:** Resplandores púrpuras vibrantes (`#7C3AED` a `#8B5CF6`).
- **Ventana Unificada:** Dimensiones fijas de `760 x 560 pt` con barra de título integrada y controles de ventana nativos.

---

## 🚦 Estado de las Fases (Roadmap)

- [x] **Fase 1:** Andamiaje del proyecto macOS, arquitectura de capas y sistema de diseño base Figma.
- [x] **Fase 2:** Perfeccionamiento visual milimétrico: orbe Liquid Glass nativo Apple, tipografía Inter, luces de fondo y resplandor neón pulsante continuo en bucle.
- [x] **Fase 3:** Ingesta por Drag & Drop y NSOpenPanel, inspección asíncrona con `ffprobe` y validación de límite de 40 videos con alerta roja.
- [x] **Fase 4:** Vista de confirmación y configuración del lote (`ConfirmarCompresion_2.png`): switches de compresión y modo privado, selector de formato desplegable (MP4, MOV, MP3) y botonera de acción con cápsula de cancelación roja y botón dinámico.
- [x] **Fase 5:** Motor de conversión `ffmpeg`, ejecución en tiempo real con monitoreo de progreso/ETA, cola de videos activa (`ConvertingView`), validación de integridad previa, envío seguro a Papelera de macOS y pantalla de finalización (`CompletedView`).
- [ ] **Fase 6:** Notificaciones nativas del sistema (`UserNotifications`) y pulido final de distribución.

---

## 📁 Arquitectura del Proyecto

```text
onestepconverter/
├── assets/
│   └── logo.png                        # Logotipo oficial para documentación
├── onestepconverter/
│   ├── onestepconverterApp.swift       # Punto de entrada y configuración de ventana (760x560)
│   ├── Assets.xcassets/                # Catálogo de iconos nativos macOS y colores
│   ├── App/
│   │   └── AppDelegate.swift           # Gestión de ciclo de vida y notificaciones
│   ├── Core/
│   │   ├── Models/                     # VideoItem, ConversionProfile, ConversionOptions
│   │   ├── Services/                   # FFmpegLocator, VideoInspector, VideoProcessor, FileTrashManager
│   │   └── ViewModels/                 # QueueViewModel (@Observable)
│   └── UI/
│       ├── Theme/                      # AppTheme (paleta, degradados, tipografía, dimensiones)
│       ├── Components/                 # GlowingOrbView, NeonProgressBar, VideoRowView
│       └── Views/                      # MainContainerView, DropzoneView, ConvertingView, CompletedView
└── onestepconverter.xcodeproj/        # Configuración del proyecto Xcode (Declarativo)
```

---

## 🚀 Compilación y Desarrollo

### Prerrequisitos
- Mac con procesador Apple Silicon o Intel.
- macOS 14.0 o superior.
- Xcode 15+ o Xcode 16/27+.
- `ffmpeg` y `ffprobe` instalados (recomendado vía Homebrew: `brew install ffmpeg`).

### Pasos para compilar
1. Clona el repositorio:
   ```bash
   git clone https://github.com/tu-usuario/onestepconverter.git
   cd onestepconverter
   ```
2. Abre el proyecto en Xcode:
   ```bash
   open onestepconverter.xcodeproj
   ```
3. O compila directamente desde la terminal:
   ```bash
   xcodebuild -project onestepconverter.xcodeproj \
     -scheme onestepconverter \
     -destination 'platform=macOS,arch=arm64' \
     -configuration Debug build
   ```

---

## 📄 Licencia

Este proyecto es de **código abierto** bajo la licencia [MIT](LICENSE) (o de libre uso personal y comunitario). Las contribuciones son bienvenidas siguiendo la metodología de especificaciones.

