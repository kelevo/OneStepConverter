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

    var body: some View {
        ZStack {
            // Capa 1: Resplandor exterior difuso
            if showGlow {
                Circle()
                    .fill(AppTheme.Colors.neonPurple.opacity(0.15))
                    .frame(width: diameter * 1.4, height: diameter * 1.4)
                    .blur(radius: AppTheme.Dimensions.orbGlowRadius)
            }

            // Capa 2: Relleno glass con degradado radial
            Circle()
                .fill(AppTheme.Gradients.orbFill)
                .frame(width: diameter, height: diameter)

            // Capa 3: Borde brillante sutil
            Circle()
                .stroke(AppTheme.Colors.orbBorder, lineWidth: AppTheme.Dimensions.orbBorderWidth)
                .frame(width: diameter, height: diameter)

            // Capa 4: Ícono SF Symbol
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .shadow(
            color: AppTheme.Effects.glowShadow,
            radius: AppTheme.Effects.glowShadowRadius
        )
    }
}

// MARK: - Variantes Pre-configuradas
extension GlowingOrbView {
    /// Orbe grande para la Dropzone (Vista 1) con ícono de subida
    static var uploadOrb: GlowingOrbView {
        GlowingOrbView(systemName: "arrow.up.to.line")
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
        GlowingOrbView.uploadOrb
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

