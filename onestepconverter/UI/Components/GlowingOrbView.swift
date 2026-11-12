//
//  GlowingOrbView.swift
//  OneStepConverter
//
//  Orbe circular Liquid Glass con APIs nativas de Apple (.ultraThinMaterial),
//  ícono de Figma al 150% de tamaño y resplandor neón morado de alta intensidad.
//

import SwiftUI

struct GlowingOrbView: View {
    var diameter: CGFloat = AppTheme.Dimensions.orbDiameter
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            // Capa 1: Liquid Glass nativo de Apple (Shader Metal de refracción y desenfoque)
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: diameter, height: diameter)

            // Capa 2: Tinte violeta espacial translúcido (#3B3486 al 15%)
            Circle()
                .fill(AppTheme.Colors.glassOrbFill)
                .frame(width: diameter, height: diameter)

            // Capa 3: Gradiente de luz especular y refracción a -45° (Figma Glass effect)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.24),
                            Color.white.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: diameter, height: diameter)

            // Capa 4: Borde reflectivo exterior a -45°
            Circle()
                .stroke(
                    AppTheme.Gradients.glassStroke,
                    lineWidth: 1.2
                )
                .frame(width: diameter, height: diameter)

            // Capa 5: Ícono oficial de Figma (IconoFlechaFigma) ampliado un 50% (165 x 165 pt)
            Image("UploadArrow")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 165, height: 165)
                .foregroundStyle(Color.white)
                .offset(y: -2)
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(isHighlighted ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
    }
}

// MARK: - Resplandor Neón Púrpura de Alta Intensidad
struct OrbNeonGlowView: View {
    var diameter: CGFloat = AppTheme.Dimensions.orbDiameter
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            // Halo exterior difuso de gran alcance (morado intenso)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.Colors.neonPurple.opacity(isHighlighted ? 0.95 : 0.80),
                            AppTheme.Colors.accentPurple.opacity(isHighlighted ? 0.70 : 0.50),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: diameter * 0.95
                    )
                )
                .frame(width: diameter * 1.70, height: diameter * 1.70)
                .blur(radius: isHighlighted ? 45 : 35)

            // Núcleo brillante concentrado
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.Colors.neonPurpleLight.opacity(isHighlighted ? 0.85 : 0.65),
                            AppTheme.Colors.neonPurple.opacity(isHighlighted ? 0.50 : 0.35),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: diameter * 0.55
                    )
                )
                .frame(width: diameter * 1.15, height: diameter * 1.15)
                .blur(radius: 20)
        }
        .scaleEffect(isHighlighted ? 1.06 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color(hex: "#000320")
            .ignoresSafeArea()
        OrbNeonGlowView(isHighlighted: false)
        GlowingOrbView(isHighlighted: false)
    }
    .frame(width: 400, height: 400)
}
