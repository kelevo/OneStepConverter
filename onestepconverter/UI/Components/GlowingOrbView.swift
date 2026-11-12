//
//  GlowingOrbView.swift
//  OneStepConverter
//
//  Orbe circular glass con ícono de Figma y soporte para micro-interacciones.
//

import SwiftUI

struct GlowingOrbView: View {
    var diameter: CGFloat = AppTheme.Dimensions.orbDiameter
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            // Capa 1: Relleno glass translúcido con gradiente a -45°
            Circle()
                .fill(AppTheme.Gradients.glassOrbGradient)
                .frame(width: diameter, height: diameter)

            // Capa 2: Reflejo superior para realzar el efecto glass
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 10,
                        endRadius: diameter * 0.75
                    )
                )
                .frame(width: diameter, height: diameter)

            // Capa 3: Borde glass reflectivo a -45°
            Circle()
                .stroke(
                    AppTheme.Gradients.glassStroke,
                    lineWidth: 1.2
                )
                .frame(width: diameter, height: diameter)

            // Capa 4: Ícono oficial de Figma (IconoFlechaFigma)
            Image("UploadArrow")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 110, height: 110)
                .foregroundStyle(Color.white)
                .offset(y: -2)
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(isHighlighted ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
    }
}

// MARK: - Componente del Destello Neón Independiente
struct OrbNeonGlowView: View {
    var diameter: CGFloat = AppTheme.Dimensions.orbDiameter
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            // Brillo púrpura profundo difuso que se expande hacia abajo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.Colors.neonPurple.opacity(isHighlighted ? 0.70 : 0.45),
                            AppTheme.Colors.accentPurple.opacity(isHighlighted ? 0.40 : 0.20),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: diameter * 0.85
                    )
                )
                .frame(width: diameter * 1.55, height: diameter * 1.55)
                .blur(radius: isHighlighted ? 36 : 28)

            // Núcleo brillante
            Circle()
                .fill(AppTheme.Colors.neonPurpleLight.opacity(isHighlighted ? 0.35 : 0.15))
                .frame(width: diameter * 1.1, height: diameter * 1.1)
                .blur(radius: 20)
        }
        .scaleEffect(isHighlighted ? 1.06 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.spaceBlack
            .ignoresSafeArea()
        OrbNeonGlowView(isHighlighted: false)
        GlowingOrbView(isHighlighted: false)
    }
    .frame(width: 400, height: 400)
}
