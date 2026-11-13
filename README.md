<p align="center">
  <img src="assets/logo.png" alt="OneStepConverter Logo" width="160" height="160" style="border-radius: 36px; box-shadow: 0 10px 30px rgba(124, 58, 237, 0.4);">
</p>

<h1 align="center">OneStepConverter</h1>

<p align="center">
  <strong>Conversor y compresor de lotes de video nativo para macOS en un solo paso</strong><br>
  <em>By Patrick Jhonatan Hernandez</em>
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

**OneStepConverter** es una aplicación de escritorio nativa para macOS diseñada para simplificar y automatizar en un solo paso el procesamiento, normalización y compresión de lotes de video.

### El problema que resuelve
Anteriormente, normalizar y comprimir lotes de video requería un flujo engorroso con hasta tres herramientas distintas:
1. **Smart Converter:** Para convertir formatos incompatibles (`.avi`, `.mkv`, `.ts`, etc.) a formato universal `.mp4` (H.264 + AAC).
2. **Video Compressor:** Para reducir drásticamente el peso de los archivos, lo cual generaba contenedores intermedios `.mov`.
3. **Atajos / FFmpeg CLI:** Un script de terminal (`ffmpeg -i input.mov -c copy output.mp4`) para re-empaquetar los `.mov` de vuelta a `.mp4` universal sin recomprimir.

### La solución en un solo paso
**OneStepConverter** reemplaza todo ese flujo en una sola pasada directa:
- **Inspección automática (`ffprobe`):** Analiza códecs, resoluciones, bitrate y duración exacta en microsegundos.
- **Ingesta por Lote (hasta 40 videos):** Soporta arrastrar y soltar (Drag & Drop) o selección nativa de carpetas con escaneo recursivo inteligente.
- **Regla de Umbral de Compresión (< 300MB):** Los videos con peso menor a 300 MB **no se comprimen** innecesariamente. Si ya son compatibles, se remuxean al instante (`-c copy`); si provienen de formatos obsoletos (`.avi`, `.mkv`, etc.), se transcodifican en alta fidelidad (`-crf 18`) sin degradación ni aumento de peso. Los videos mayores o iguales a 300 MB se comprimen de forma balanceada (`-crf 26`).
- **Modo Privado:** Enmascara dinámicamente los nombres reales de los videos en la interfaz (mostrando "Video 1", "Video 2", etc.) para proteger la privacidad durante grabaciones o uso en público.
- **Formatos Universales:** Soporte de salida en **MP4** ("tipo Android", universalmente compatible en cualquier reproductor), **MOV** o extracción de pista de audio en **MP3**.
- **Monitoreo de Progreso y ETA en tiempo real:** Lectura precisa del pipe de FFmpeg para calcular porcentaje exacto y tiempo restante estimado en lenguaje natural.
- **Seguridad Absoluta de Archivos:** Valida la integridad del archivo resultante (`terminationStatus == 0`, tamaño > 0, duración concordante) antes de mover el archivo original a la **Papelera de macOS** mediante `FileManager.trashItem`.
- **Métricas de Reducción y Notificaciones:** Resumen detallado del espacio recuperado en disco y alertas nativas del sistema con `UserNotifications`.

---

## ✨ Características Principales

- **Diseño Espacial Dark Mode:** Interfaz construida en SwiftUI nativo con materiales Liquid Glass (`.ultraThinMaterial`), reflejos a -45° y resplandor neón púrpura pulsante continuo.
- **Motor Asíncrono Swift 6:** Arquitectura basada en actores de concurrencia (`actor VideoProcessor`, `@Observable QueueViewModel`) sin bloqueos en el hilo principal.
- **Límite Inteligente de Ingesta:** Protección de hasta 40 videos por lote con alerta visual en rojo neón y temporizador automático de recuperación.
- **Cancelación Granular:** Permite omitir o eliminar videos individuales de la cola sin interrumpir el procesamiento del resto del lote.

---

## 💻 Requisitos del Sistema

- **Sistema Operativo:** macOS 14.0 Sonoma, macOS 15 Sequoia o superior.
- **Arquitectura:** Apple Silicon (M1/M2/M3/M4) e Intel (x86_64).
- **Motor Multimedia:** `ffmpeg` y `ffprobe` instalados en el sistema (rutas estándar `/opt/homebrew/bin` o `/usr/local/bin`).

### Instalación de dependencias (Homebrew)
Si aún no cuentas con FFmpeg en tu Mac, instálalo fácilmente con:
```bash
brew install ffmpeg
```

---

## 📦 Instalación

### Opción 1: Archivo `.dmg` (Recomendado)
1. Descarga la versión más reciente de `OneStepConverter.dmg` desde la sección de **Releases** en GitHub.
2. Abre el archivo `.dmg` y arrastra **OneStepConverter.app** a tu carpeta **/Applications**.
3. Abre OneStepConverter desde Spotlight o tu carpeta de Aplicaciones.
   > **Nota sobre macOS Gatekeeper:** Al ser una distribución independiente de código abierto con firma ad-hoc, si macOS muestra la advertencia *"OneStepConverter no se puede abrir porque el desarrollador no ha sido verificado"*, haz clic derecho sobre la aplicación en `/Applications` y selecciona **Abrir**, luego confirma la apertura. Solo es necesario la primera vez.

---

## 🛠️ Compilación y Empaquetado desde Código Fuente

### Prerrequisitos para desarrolladores
- macOS 14.0+ con Xcode 15 o superior instalado.
- Herramientas de línea de comandos de Xcode (`xcode-select --install`).

### Compilar en modo Debug
```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/onestepconverter.git
cd onestepconverter

# Compilar con xcodebuild
xcodebuild -project onestepconverter.xcodeproj \
  -scheme onestepconverter \
  -configuration Debug build
```

### Generar el Instalador DMG (Release)
El proyecto incluye un script automatizado para compilar en Release, aplicar firma de código ad-hoc y empaquetar el instalador `.dmg`:
```bash
./scripts/build_dmg.sh
```
El instalador resultante estará disponible en `dist/OneStepConverter.dmg`.

---

## 📁 Arquitectura del Proyecto

```text
onestepconverter/
├── assets/
│   └── logo.png                        # Logotipo oficial para documentación
├── scripts/
│   └── build_dmg.sh                    # Script de compilación y empaquetado DMG
├── specs/                              # Especificaciones de desarrollo (SDD)
├── onestepconverter/
│   ├── onestepconverterApp.swift       # Punto de entrada y configuración de ventana (760x560)
│   ├── App/
│   │   └── AppDelegate.swift           # Ciclo de vida y notificaciones (UNUserNotificationCenter)
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── VideoItem.swift         # Modelo de datos, estados, progreso, ETA y regla 300MB
│   │   │   ├── ConversionProfile.swift # Perfiles de codificación (Equilibrado, Rápido, Audio)
│   │   │   └── ConversionOptions.swift # Configuración de lote (comprimir, modo privado, formato)
│   │   ├── Services/
│   │   │   ├── FFmpegLocator.swift     # Detección dinámica de ffmpeg/ffprobe en macOS
│   │   │   ├── VideoInspector.swift    # Inspección de metadatos JSON con ffprobe
│   │   │   ├── VideoProcessor.swift    # Motor de ejecución de FFmpeg y lectura de pipe:1
│   │   │   ├── FileTrashManager.swift  # Validación de salida y envío a Papelera de macOS
│   │   │   └── NotificationManager.swift # Despacho de notificaciones locales de macOS
│   │   └── ViewModels/
│   │       └── QueueViewModel.swift    # Orquestador observable del estado y la cola
│   ├── UI/
│   │   ├── Theme/
│   │   │   └── AppTheme.swift          # Gradientes, paleta de colores espaciales y estilos
│   │   ├── Components/
│   │   │   ├── GlowingOrbView.swift    # Orbe Liquid Glass reutilizable con resplandor neón
│   │   │   ├── NeonProgressBar.swift   # Barra de progreso púrpura neón
│   │   │   └── VideoRowView.swift      # Fila de video con progreso y botón individual
│   │   └── Views/
│   │       ├── MainContainerView.swift # Enrutador de estados de navegación
│   │       ├── DropzoneView.swift      # Vista 1 e intermedia (Inicio y Confirmar Lote)
│   │       ├── ConvertingView.swift    # Vista 2 (Cola de conversión y progreso global)
│   │       └── CompletedView.swift     # Vista 3 (Resumen de métricas de reducción)
│   ├── Resources/
│   │   ├── Fonts/                      # Tipografías Inter integradas
│   │   └── Logo.png                    # Icono en alta resolución
│   └── Assets.xcassets/                # Catálogo de imágenes vectoriales y AppIcon
└── onestepconverter.xcodeproj/        # Configuración del proyecto Xcode
```

---

## 📐 Metodología: Spec-Driven Development (SDD)

Este proyecto fue desarrollado íntegramente bajo la metodología **Spec-Driven Development (SDD)**:
- Cada módulo, vista y ajuste técnico cuenta con una especificación previa en la carpeta `specs/`.
- El código se implementa en ramas dedicadas (`feat/...`) verificando criterios de aceptación estrictos antes de su integración.

---

## 👤 Autor y Créditos

Desarrollado con dedicación por:
- **Patrick Jhonatan Hernandez** — *Arquitectura, Diseño y Desarrollo*

---

## 📄 Licencia

Este proyecto es de código abierto bajo la licencia [MIT](LICENSE).
