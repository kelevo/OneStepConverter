//
//  AppTheme.swift
//  OneStepConverter
//
//  Sistema de diseño: paleta espacial oscura con acentos neón púrpura.
//

import SwiftUI

// MARK: - Namespace del Tema
enum AppTheme {

    // MARK: - Colores Base (de colors.md / Figma + AGENTS.md)
    enum Colors {
        /// Negro profundo espacial — fondo inferior / base absoluta
        static let spaceBlack       = Color(hex: "#000320")
        /// Azul medianoche oscuro — zona inferior del degradado principal
        static let midnightDeep     = Color(hex: "#080D2D")
        /// Azul medianoche — zona superior del degradado principal
        static let midnightBlue     = Color(hex: "#101639")
        /// Superficie glass / tarjetas translúcidas
        static let glassSurface     = Color(hex: "#1F2951")
        /// Bordes sutiles y divisores
        static let subtleBorder     = Color(hex: "#2E3C6A")
        /// Púrpura acento primario (Figma)
        static let accentPurple     = Color(hex: "#864AF9")

        // Colores de AGENTS.md (complementarios)
        /// Púrpura vibrante — inicio del degradado de acento
        static let neonPurple       = Color(hex: "#7C3AED")
        /// Púrpura brillante — fin del degradado de acento / barras de progreso
        static let neonPurpleLight  = Color(hex: "#8B5CF6")

        // Texto
        /// Texto principal — títulos y contenido primario
        static let textPrimary      = Color.white
        /// Texto secundario — metadatos y subtítulos
        static let textSecondary    = Color(hex: "#94A3B8")

        // Superficies con opacidad
        /// Superficie glass con opacidad (75%)
        static let glassSurfaceTranslucent = Color(hex: "#1E2246").opacity(0.75)
        /// Borde sutil blanco (15%)
        static let glowBorder       = Color.white.opacity(0.15)
        /// Borde orbe brillante (lila sutil)
        static let orbBorder        = Color(hex: "#8B5CF6").opacity(0.4)
    }

    // MARK: - Degradados
    enum Gradients {
        /// Fondo principal de la app (degradado vertical profundo)
        static let mainBackground = LinearGradient(
            colors: [
                Colors.midnightBlue,   // #101639 arriba
                Colors.midnightDeep,   // #080D2D medio
                Colors.spaceBlack      // #000320 abajo
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        /// Degradado del orbe (relleno translúcido púrpura)
        static let orbFill = RadialGradient(
            colors: [
                Colors.neonPurple.opacity(0.3),
                Colors.glassSurface.opacity(0.5),
                Colors.midnightDeep.opacity(0.8)
            ],
            center: .center,
            startRadius: 20,
            endRadius: 100
        )

        /// Degradado del acento para barras de progreso
        static let neonAccent = LinearGradient(
            colors: [Colors.neonPurple, Colors.neonPurpleLight],
            startPoint: .leading,
            endPoint: .trailing
        )

        /// Degradado para botones tipo cápsula
        static let capsuleButton = LinearGradient(
            colors: [
                Colors.glassSurface,
                Colors.glassSurface.opacity(0.8)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Tipografía
    enum Typography {
        /// Título principal — "ARRASTRA TUS VÍDEOS AQUÍ", "CONVIRTIENDO", etc.
        static let screenTitleFont = Font.system(size: 22, weight: .bold, design: .default)
        static let screenTitleTracking: CGFloat = 3.0

        /// Contador global — "2 de 10 videos"
        static let counterFont = Font.system(size: 18, weight: .bold, design: .default)

        /// Subtexto — "20 minutos restantes"
        static let subtextFont = Font.system(size: 13, weight: .regular, design: .default)

        /// Nombre de archivo en la fila de video
        static let fileNameFont = Font.system(size: 15, weight: .semibold, design: .default)

        /// Metadatos de archivo en la fila de video
        static let metadataFont = Font.system(size: 12, weight: .regular, design: .default)

        /// Botón cápsula — "SELECCIONAR CARPETA"
        static let buttonFont = Font.system(size: 14, weight: .semibold, design: .default)
    }

    // MARK: - Dimensiones
    enum Dimensions {
        /// Tamaño de la ventana
        static let windowWidth: CGFloat = 760
        static let windowHeight: CGFloat = 560

        /// Orbe central (dropzone / completado)
        static let orbDiameter: CGFloat = 180

        /// Ícono dentro del orbe
        static let orbIconSize: CGFloat = 60

        /// Ícono circular de la fila de video
        static let rowIconDiameter: CGFloat = 44

        /// Botón cancelar en la fila de video
        static let cancelButtonDiameter: CGFloat = 28

        /// Altura de la barra de progreso individual
        static let progressBarHeight: CGFloat = 4

        /// Altura de la barra de progreso global
        static let globalProgressBarHeight: CGFloat = 6

        /// Radio de esquinas del botón cápsula
        static let capsuleCornerRadius: CGFloat = 12

        /// Ancho del borde del orbe
        static let orbBorderWidth: CGFloat = 1.0

        /// Radio del resplandor exterior del orbe
        static let orbGlowRadius: CGFloat = 24
    }

    // MARK: - Efectos
    enum Effects {
        /// Sombra de resplandor púrpura
        static let glowShadow = Color(hex: "#7C3AED").opacity(0.55)
        static let glowShadowRadius: CGFloat = 24
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
            .font(AppTheme.Typography.screenTitleFont)
            .tracking(AppTheme.Typography.screenTitleTracking)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .textCase(.uppercase)
    }
}

extension View {
    /// Aplica el estilo de título de pantalla (Bold, Uppercase, Tracking amplio)
    func screenTitleStyle() -> some View {
        self.modifier(ScreenTitleModifier())
    }

    /// Aplica el fondo espacial principal de la app
    func spaceBackground() -> some View {
        self.background(AppTheme.Gradients.mainBackground)
    }
}

