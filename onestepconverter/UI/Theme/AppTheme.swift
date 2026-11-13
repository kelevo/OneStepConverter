//
//  AppTheme.swift
//  OneStepConverter
//
//  Sistema de diseño: paleta espacial oscura con acentos neón púrpura (Figma).
//

import SwiftUI

// MARK: - Namespace del Tema
enum AppTheme {

    // MARK: - Colores Base (de Figma)
    enum Colors {
        /// Negro profundo espacial — base absoluta (#000320)
        static let spaceBlack       = Color(hex: "#000320")
        /// Azul medianoche oscuro (#080D2D)
        static let midnightDeep     = Color(hex: "#080D2D")
        /// Azul medianoche (#101639)
        static let midnightBlue     = Color(hex: "#101639")
        /// Color de las luces de fondo desenfocadas (#2E3C6A)
        static let backgroundLight  = Color(hex: "#2E3C6A")
        /// Fondo del botón "SELECCIONAR CARPETA" (#1F2951)
        static let buttonBackground = Color(hex: "#1F2951")
        /// Superficie glass / tarjetas translúcidas (#1F2951)
        static let glassSurface     = Color(hex: "#1F2951")
        /// Relleno del contenedor glass de la flecha (#3B3486 al 12%)
        static let glassOrbFill     = Color(hex: "#3B3486").opacity(0.12)
        /// Púrpura acento primario (#864AF9)
        static let accentPurple     = Color(hex: "#864AF9")

        // Acentos neón
        /// Púrpura neón vibrante (#7C3AED)
        static let neonPurple       = Color(hex: "#7C3AED")
        /// Púrpura neón brillante (#8B5CF6)
        static let neonPurpleLight  = Color(hex: "#8B5CF6")

        // Texto
        /// Texto principal (#FFFFFF)
        static let textPrimary      = Color.white
        /// Texto secundario (#94A3B8)
        static let textSecondary    = Color(hex: "#94A3B8")

        // Superficies y bordes
        /// Superficie glass con opacidad (75%)
        static let glassSurfaceTranslucent = Color(hex: "#1E2246").opacity(0.75)
        /// Borde sutil blanco (15%)
        static let glowBorder       = Color.white.opacity(0.15)
        /// Borde del orbe brillante (lila)
        static let orbBorder        = Color(hex: "#8B5CF6").opacity(0.4)

        // Botón cancelar y alertas de error (Fase 3 y 4)
        /// Rojo del botón de cancelar (#850002)
        static let cancelRed            = Color(hex: "#850002")
        /// Sombra del botón de cancelar (#FF0004 al 25%)
        static let cancelRedGlow        = Color(hex: "#FF0004").opacity(0.25)
        /// Cápsula roja oscura de cancelación en ConfirmarCompresion_2 (#850002)
        static let cancelDarkRed        = Color(hex: "#850002")
        /// Estado hover para cápsula roja oscura (#9E0003)
        static let cancelDarkRedHover   = Color(hex: "#9E0003")
        /// Sombra difusa para cápsula roja (Figma: #FF0004 al 25%, Blur 60, Y 10, X 0)
        static let cancelDarkRedGlow    = Color(hex: "#FF0004").opacity(0.25)
        /// Color púrpura del switch activo (#8B5CF6)
        static let switchActive         = Color(hex: "#8B5CF6")
        /// Fondo de la cápsula de formato de salida (blanco puro)
        static let formatCapsuleBackground = Color.white
        /// Texto de la cápsula de formato de salida (#000320)
        static let formatCapsuleText    = Color(hex: "#000320")
        /// Rojo vibrante para estado de límite excedido (#EF4444)
        static let errorRed             = Color(hex: "#EF4444")
        /// Rojo oscuro para degradado de error (#DC2626)
        static let errorRedDark         = Color(hex: "#DC2626")
    }

    // MARK: - Degradados
    enum Gradients {
        /// Fondo principal de la app
        static let mainBackground = LinearGradient(
            colors: [
                Colors.midnightBlue,
                Colors.midnightDeep,
                Colors.spaceBlack
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        /// Relleno glass del orbe (degradado diagonal sutil estilo Figma -45°)
        static let glassOrbGradient = LinearGradient(
            colors: [
                Color.white.opacity(0.16),
                Colors.glassOrbFill,
                Color(hex: "#3B3486").opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Borde glass reflectivo (-45°)
        static let glassStroke = LinearGradient(
            colors: [
                Color.white.opacity(0.55),
                Color.white.opacity(0.15),
                Color(hex: "#8B5CF6").opacity(0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Degradado del acento para barras de progreso
        static let neonAccent = LinearGradient(
            colors: [Colors.neonPurple, Colors.neonPurpleLight],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Tipografía
    enum Typography {
        /// Título principal — "ARRASTRA TUS VÍDEOS AQUÍ" (Inter Bold 30pt, -20%)
        static let screenTitleFont = Font.custom("Inter-Regular_Bold", size: 30)
        static let screenTitleFallback = Font.custom("Inter", size: 30).weight(.bold)
        static let screenTitleTracking: CGFloat = 2.0

        /// Botón cápsula — "SELECCIONAR CARPETA" (Inter SemiBold 13pt)
        static let buttonFont = Font.custom("Inter-Regular_SemiBold", size: 13)
        static let buttonFontFallback = Font.custom("Inter", size: 13).weight(.semibold)
        static let buttonTracking: CGFloat = 1.5

        /// Título de ventana — "OneStepConverter" (12pt regular)
        static let windowTitleFont = Font.custom("Inter-Regular", size: 12)

        /// Contador de videos dentro del orbe (Fase 3 — ConfirmarCompresion)
        static let counterFont = Font.custom("Inter-Regular_Bold", size: 48)
        static let counterFontFallback = Font.custom("Inter", size: 48).weight(.bold)
        static let counterLabelFont = Font.custom("Inter-Regular", size: 14)
        static let counterLabelFontFallback = Font.custom("Inter", size: 14)

        /// Etiquetas de opciones en ConfirmarCompresion_2 (14pt regular)
        static let optionLabelFont = Font.custom("Inter-Regular", size: 14)
        static let optionLabelFontFallback = Font.custom("Inter", size: 14)

        /// Selector de formato (12pt SemiBold)
        static let formatPickerFont = Font.custom("Inter-Regular_SemiBold", size: 12)
        static let formatPickerFontFallback = Font.custom("Inter", size: 12).weight(.semibold)
    }

    // MARK: - Dimensiones (Extraídas de Figma)
    enum Dimensions {
        /// Tamaño de la ventana
        static let windowWidth: CGFloat = 760
        static let windowHeight: CGFloat = 560

        /// Área activa de arrastre central (Dropzone)
        static let dropzoneActiveWidth: CGFloat = 460
        static let dropzoneActiveHeight: CGFloat = 260

        /// Diámetro del orbe central en pantalla de inicio (Figma: W 222, H 222)
        static let orbDiameter: CGFloat = 222

        /// Diámetro del orbe central en vista de confirmación (Figma: W 180, H 180)
        static let confirmOrbDiameter: CGFloat = 180

        /// Espaciado exacto entre título y orbe
        static let titleToOrbSpacing: CGFloat = 58

        /// Espaciado exacto entre orbe y botón (Figma: 41 pt)
        static let orbToButtonSpacing: CGFloat = 41

        /// Botón "SELECCIONAR CARPETA" (Figma: 230 x 43 pt)
        static let buttonWidth: CGFloat = 230
        static let buttonHeight: CGFloat = 43

        /// Botones de acción en ConfirmarCompresion_2
        static let confirmCancelButtonWidth: CGFloat = 150
        static let confirmConvertButtonWidth: CGFloat = 240
        static let optionsSpacing: CGFloat = 38

        /// Luces de fondo (Figma: 591 x 591 pt con blur 400)
        static let backgroundLightDiameter: CGFloat = 591
        static let backgroundLightBlur: CGFloat = 140

        /// Ícono circular de la fila de video
        static let rowIconDiameter: CGFloat = 44
        static let cancelButtonDiameter: CGFloat = 28
        static let progressBarHeight: CGFloat = 4
        static let globalProgressBarHeight: CGFloat = 6
        static let capsuleCornerRadius: CGFloat = 14
    }
}

// MARK: - Color Extension (Hex Initializer)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct ScreenTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.screenTitleFallback)
            .tracking(AppTheme.Typography.screenTitleTracking)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .textCase(.uppercase)
    }
}

extension View {
    func screenTitleStyle() -> some View {
        self.modifier(ScreenTitleModifier())
    }

    /// Aplica el fondo espacial principal de la app
    func spaceBackground() -> some View {
        self.background(AppTheme.Colors.spaceBlack)
    }
}
