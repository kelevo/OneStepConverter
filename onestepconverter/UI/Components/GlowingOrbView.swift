//
//  GlowingOrbView.swift
//  OneStepConverter
//
//  Orbe circular Liquid Glass con APIs nativas de Apple (.ultraThinMaterial),
//  soporte para ícono de flecha, ícono de carga y contador de videos (Fase 3).
//

import SwiftUI

/// Tipo de contenido visual dentro del orbe Liquid Glass
enum OrbContentType: Equatable {
    case uploadArrow
    case addingIcon
    case counter(Int)
}

struct GlowingOrbView: View {
    var diameter: CGFloat = AppTheme.Dimensions.orbDiameter
    var contentType: OrbContentType = .uploadArrow
    var accentColor: Color = AppTheme.Colors.neonPurple
    var isHighlighted: Bool = false

    private var isErrorState: Bool {
        accentColor == AppTheme.Colors.errorRed
    }

    var body: some View {
        ZStack {
            // Capa 1: Liquid Glass nativo de Apple (Shader Metal de refracción y desenfoque)
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: diameter, height: diameter)

            // Capa 2: Tinte espacial translúcido (violeta o rojo si es error)
            Circle()
                .fill(
                    isErrorState
                        ? AppTheme.Colors.errorRed.opacity(0.12)
                        : AppTheme.Colors.glassOrbFill
                )
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
                    isErrorState ? glassErrorStroke : AppTheme.Gradients.glassStroke,
                    lineWidth: 1.2
                )
                .frame(width: diameter, height: diameter)

            // Capa 5: Contenido central según el estado
            orbContent
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(isHighlighted ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
        .animation(.easeInOut(duration: 0.3), value: accentColor)
    }

    // MARK: - Contenido Central
    @ViewBuilder
    private var orbContent: some View {
        let iconSize = diameter * (132.0 / 222.0)

        switch contentType {
        case .uploadArrow:
            Image("UploadArrow")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(Color.white)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

        case .addingIcon:
            Image("IconoAgregando")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(Color.white)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

        case .counter(let count):
            VStack(spacing: diameter <= 180 ? 2 : 4) {
                Text("\(count)")
                    .font(diameter <= 180 ? Font.custom("Inter", size: 44).weight(.bold) : AppTheme.Typography.counterFontFallback)
                    .foregroundStyle(Color.white)

                Text("Videos Agregados")
                    .font(diameter <= 180 ? Font.custom("Inter", size: 13) : AppTheme.Typography.counterLabelFontFallback)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    private var glassErrorStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.65),
                Color.white.opacity(0.20),
                AppTheme.Colors.errorRed.opacity(0.70)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Resplandor Neón Pulsante Continuo (Breathing Glow con Acento Dinámico)
struct OrbNeonGlowView: View {
    var diameter: CGFloat = AppTheme.Dimensions.orbDiameter
    var accentColor: Color = AppTheme.Colors.neonPurple
    var isTargeted: Bool = false
    @State private var isPulsing: Bool = false

    private var isErrorState: Bool {
        accentColor == AppTheme.Colors.errorRed
    }

    var body: some View {
        ZStack {
            // Halo exterior difuso de gran alcance que respira en bucle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            outerColor1.opacity(isTargeted ? 0.98 : (isPulsing ? 0.92 : 0.65)),
                            outerColor2.opacity(isTargeted ? 0.80 : (isPulsing ? 0.65 : 0.35)),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: diameter * 0.95
                    )
                )
                .frame(width: diameter * 1.70, height: diameter * 1.70)
                .blur(radius: isPulsing ? 46 : 34)

            // Núcleo brillante concentrado
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            coreColor1.opacity(isTargeted ? 0.90 : (isPulsing ? 0.82 : 0.50)),
                            coreColor2.opacity(isTargeted ? 0.65 : (isPulsing ? 0.50 : 0.25)),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: diameter * 0.55
                    )
                )
                .frame(width: diameter * 1.15, height: diameter * 1.15)
                .blur(radius: isPulsing ? 24 : 18)
        }
        .scaleEffect(isTargeted ? 1.10 : (isPulsing ? 1.08 : 0.96))
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .animation(.easeInOut(duration: 0.35), value: accentColor)
        .allowsHitTesting(false)
    }

    // MARK: - Paleta Dinámica según Estado
    private var outerColor1: Color {
        isErrorState ? AppTheme.Colors.errorRed : AppTheme.Colors.neonPurple
    }

    private var outerColor2: Color {
        isErrorState ? AppTheme.Colors.errorRedDark : AppTheme.Colors.accentPurple
    }

    private var coreColor1: Color {
        isErrorState ? AppTheme.Colors.errorRed : AppTheme.Colors.neonPurpleLight
    }

    private var coreColor2: Color {
        isErrorState ? AppTheme.Colors.errorRedDark : AppTheme.Colors.neonPurple
    }
}

#Preview {
    ZStack {
        Color(hex: "#000320")
            .ignoresSafeArea()
        GlowingOrbView(contentType: .counter(20))
    }
}
