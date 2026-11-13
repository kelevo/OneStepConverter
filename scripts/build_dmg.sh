#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# OneStepConverter — Script de Compilación y Empaquetado DMG (Release)
# By Patrick Jhonatan Hernandez
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"
STAGING_DIR="$BUILD_DIR/dmg_staging"
APP_NAME="OneStepConverter"
DMG_NAME="OneStepConverter.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
VOL_NAME="OneStepConverter"

echo "======================================================================"
echo "  Iniciando empaquetado de $APP_NAME para Release"
echo "  Directorio del proyecto: $PROJECT_ROOT"
echo "======================================================================"

# 1. Comprobación de herramientas necesarias
for cmd in xcodebuild codesign hdiutil; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Error: La herramienta obligatoria '$cmd' no está disponible." >&2
        exit 1
    fi
done

# 2. Limpieza de directorios previos
echo "🧹 Limpiando directorios previos de compilación..."
rm -rf "$BUILD_DIR"
mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"

# 3. Compilación del proyecto en modo Release
echo "🔨 Compilando $APP_NAME en configuración Release con xcodebuild..."
xcodebuild -project "$PROJECT_ROOT/onestepconverter.xcodeproj" \
    -scheme onestepconverter \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE="Manual" \
    CODE_SIGNING_REQUIRED=NO \
    clean build

APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: No se encontró el bundle de la aplicación en: $APP_PATH" >&2
    exit 1
fi

echo "✅ Compilación exitosa en: $APP_PATH"

# 4. Firma de código ad-hoc
echo "🔏 Aplicando firma de código ad-hoc..."
codesign --force --deep --sign - "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
echo "✅ Firma ad-hoc verificada correctamente."

# 5. Preparación de la carpeta de staging para el DMG
echo "📦 Preparando carpeta de distribución..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# 6. Creación del archivo .dmg comprimido con hdiutil
echo "💿 Creando imagen de disco UDZO en: $DMG_PATH..."
hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# 7. Verificación de integridad del instalador montándolo temporalmente
echo "🔍 Validando integridad del archivo DMG..."
MOUNT_POINT=$(mktemp -d /tmp/OneStepConverter_Mount.XXXXXX)

hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" -nobrowse -quiet

if [ ! -d "$MOUNT_POINT/$APP_NAME.app" ]; then
    echo "❌ Error de validación: $APP_NAME.app no existe dentro del DMG montado." >&2
    hdiutil detach "$MOUNT_POINT" -quiet || true
    rmdir "$MOUNT_POINT" || true
    exit 1
fi

if [ ! -L "$MOUNT_POINT/Applications" ]; then
    echo "❌ Error de validación: El enlace a /Applications no existe dentro del DMG montado." >&2
    hdiutil detach "$MOUNT_POINT" -quiet || true
    rmdir "$MOUNT_POINT" || true
    exit 1
fi

echo "✅ Verificación en volumen montado exitosa ($MOUNT_POINT)."
hdiutil detach "$MOUNT_POINT" -quiet
rmdir "$MOUNT_POINT"

# 8. Reporte final
DMG_SIZE=$(du -sh "$DMG_PATH" | awk '{print $1}')
echo "======================================================================"
echo "🎉 ¡Instalador generado exitosamente!"
echo "📍 Ubicación: $DMG_PATH"
echo "⚖️  Tamaño final: $DMG_SIZE"
echo "======================================================================"

