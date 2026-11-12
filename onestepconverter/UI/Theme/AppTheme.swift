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
        /// Título principal — "ARRASTRA TUS VÍDEOS AQUÍ" (Inter / SF Pro Display Bold 29pt, +30%)
        static let screenTitleFont = Font.custom("Inter-Bold", size: 29)
        static let screenTitleFallback = Font.system(size: 29, weight: .bold, design: .default)
        static let screenTitleTracking: CGFloat = 2.0

        /// Botón cápsula — "SELECCIONAR CARPETA" (Inter / SF Pro Semibold 13pt)
        static let buttonFont = Font.custom("Inter-SemiBold", size: 13)
        static let buttonFontFallback = Font.system(size: 13, weight: .semibold, design: .default)
        static let buttonTracking: CGFloat = 1.5

        /// Título de ventana — "OneStepConverter" (12pt regular)
        static let windowTitleFont = Font.system(size: 12, weight: .regular, design: .default)
    }

    // MARK: - Dimensiones (Extraídas de Figma)
    enum Dimensions {
        /// Tamaño de la ventana
        static let windowWidth: CGFloat = 760
        static let windowHeight: CGFloat = 560

        /// Diámetro del orbe central (Figma: W 222, H 222)
        static let orbDiameter: CGFloat = 222

        /// Espaciado exacto entre título y orbe (Figma: 68 pt para posición elevada)
        static let titleToOrbSpacing: CGFloat = 68

        /// Espaciado exacto entre orbe y botón (Figma: 41 pt)
        static let orbToButtonSpacing: CGFloat = 41

        /// Botón "SELECCIONAR CARPETA" (Figma: 230 x 43 pt)
        static let buttonWidth: CGFloat = 230
        static let buttonHeight: CGFloat = 43

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
