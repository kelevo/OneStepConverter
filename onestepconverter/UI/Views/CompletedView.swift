//
//  CompletedView.swift
//  OneStepConverter
//
//  Vista de proceso completado con confirmación visual de éxito y botón para convertir más videos (Figma: ConversionCompletada_2.png).
//

import SwiftUI

struct CompletedView: View {
    @Bindable var viewModel: QueueViewModel
    @State private var isButtonHovered: Bool = false

    var body: some View {
        ZStack {
            // Capa 1: Fondo espacial profundo y luces desenfocadas
            AppTheme.Gradients.mainBackground
                .ignoresSafeArea()

            backgroundLights
                .allowsHitTesting(false)

            // Capa 2: Contenido vertical centrado
            VStack(spacing: 0) {
                // Título superior
                Text("PROCESO COMPLETADO")
                    .screenTitleStyle()
                    .padding(.top, 48)

                Spacer()

                // Orbe central con resplandor neón pulsante y checkmark oficial
                ZStack {
                    OrbNeonGlowView(
                        diameter: AppTheme.Dimensions.confirmOrbDiameter,
                        accentColor: AppTheme.Colors.neonPurple,
                        isTargeted: false
                    )

                    GlowingOrbView(
                        diameter: AppTheme.Dimensions.confirmOrbDiameter,
                        contentType: .successCheckmark,
                        accentColor: AppTheme.Colors.neonPurple
                    )
                }

                Spacer()

                // Botón principal: "CONVERTIR MÁS VÍDEOS"
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.convertMoreVideos()
                    }
                }) {
                    Text("CONVERTIR MÁS VÍDEOS")
                        .font(AppTheme.Typography.buttonFontFallback)
                        .tracking(AppTheme.Typography.buttonTracking)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .frame(
                            width: AppTheme.Dimensions.buttonWidth,
                            height: AppTheme.Dimensions.buttonHeight
                        )
                        .background(
                            isButtonHovered
                                ? AppTheme.Colors.buttonBackground.opacity(0.95)
                                : AppTheme.Colors.buttonBackground
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius)
                                .stroke(
                                    isButtonHovered
                                        ? Color.white.opacity(0.35)
                                        : AppTheme.Colors.glowBorder,
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isButtonHovered
                                ? AppTheme.Colors.neonPurple.opacity(0.35)
                                : Color.clear,
                            radius: 12
                        )
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius))
                .scaleEffect(isButtonHovered ? 1.02 : 1.0)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isButtonHovered = hovering
                    }
                }
                .padding(.bottom, 64)
            }
        }
    }

    // MARK: - Luces Ambientales Desenfocadas
    private var backgroundLights: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.backgroundLight.opacity(0.50))
                .frame(
                    width: AppTheme.Dimensions.backgroundLightDiameter,
                    height: AppTheme.Dimensions.backgroundLightDiameter
                )
                .blur(radius: AppTheme.Dimensions.backgroundLightBlur)
                .offset(x: -80, y: -90)

            Circle()
                .fill(AppTheme.Colors.accentPurple.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .offset(x: 100, y: 120)
        }
    }
}

#Preview {
    CompletedView(viewModel: QueueViewModel())
        .frame(width: 760, height: 532)
}
