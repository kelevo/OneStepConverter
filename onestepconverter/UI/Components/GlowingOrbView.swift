//
//  GlowingOrbView.swift
//  OneStepConverter
//
//  Orbe circular púrpura translúcido con resplandor exterior.
//  Usado en: Dropzone (upload), Convirtiendo (video row), Completado (checkmark).
//

import SwiftUI

struct GlowingOrbView: View {
    let systemName: String
    var diameter: CGFloat = AppTheme.Dimensions.orbDiameter
    var iconSize: CGFloat = AppTheme.Dimensions.orbIconSize
    var showGlow: Bool = true
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            // Capa 1: Resplandor exterior difuso
            if showGlow {
                Circle()
                    .fill(AppTheme.Colors.neonPurple.opacity(isHighlighted ? 0.40 : 0.15))
                    .frame(
                        width: diameter * (isHighlighted ? 1.5 : 1.4),
                        height: diameter * (isHighlighted ? 1.5 : 1.4)
                    )
                    .blur(radius: isHighlighted ? 32 : AppTheme.Dimensions.orbGlowRadius)
            }

            // Capa 2: Relleno glass con degradado radial
            Circle()
                .fill(AppTheme.Gradients.orbFill)
                .frame(width: diameter, height: diameter)

            // Capa 3: Borde brillante sutil
            Circle()
                .stroke(
                    isHighlighted ? AppTheme.Colors.neonPurpleLight.opacity(0.8) : AppTheme.Colors.orbBorder,
                    lineWidth: isHighlighted ? 1.5 : AppTheme.Dimensions.orbBorderWidth
                )
                .frame(width: diameter, height: diameter)

            // Capa 4: Ícono SF Symbol
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .scaleEffect(isHighlighted ? 1.05 : 1.0)
        .shadow(
            color: isHighlighted ? AppTheme.Colors.neonPurple.opacity(0.75) : AppTheme.Effects.glowShadow,
            radius: isHighlighted ? 32 : AppTheme.Effects.glowShadowRadius
        )
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
    }
}

// MARK: - Variantes Pre-configuradas
extension GlowingOrbView {
    /// Orbe grande para la Dropzone (Vista 1) con ícono de subida
    static func uploadOrb(isHighlighted: Bool = false) -> GlowingOrbView {
        GlowingOrbView(systemName: "arrow.up.to.line", isHighlighted: isHighlighted)
    }

    /// Orbe grande para la Vista Completada (Vista 3) con checkmark
    static var completedOrb: GlowingOrbView {
        GlowingOrbView(systemName: "checkmark")
    }

    /// Orbe pequeño para la fila de video en la Vista Convirtiendo
    static var videoRowOrb: GlowingOrbView {
        GlowingOrbView(
            systemName: "video.fill",
            diameter: AppTheme.Dimensions.rowIconDiameter,
            iconSize: 18,
            showGlow: false
        )
    }
}

#Preview("Upload Orb") {
    ZStack {
        AppTheme.Gradients.mainBackground
        GlowingOrbView.uploadOrb()
    }
    .frame(width: 400, height: 400)
}

#Preview("Upload Orb Highlighted") {
    ZStack {
        AppTheme.Gradients.mainBackground
        GlowingOrbView.uploadOrb(isHighlighted: true)
    }
    .frame(width: 400, height: 400)
}

#Preview("Completed Orb") {
    ZStack {
        AppTheme.Gradients.mainBackground
        GlowingOrbView.completedOrb
    }
    .frame(width: 400, height: 400)
}

#Preview("Video Row Orb") {
    ZStack {
        AppTheme.Gradients.mainBackground
        GlowingOrbView.videoRowOrb
    }
    .frame(width: 100, height: 100)
}
