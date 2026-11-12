//
//  DropzoneView.swift
//  OneStepConverter
//
//  Vista principal de arrastrar y soltar archivos (pantalla de inicio).
//  Fiel a la referencia visual Inicio.png con micro-interacciones suaves y jerarquía Z precisa.
//

import SwiftUI

struct DropzoneView: View {
    @Binding var isTargeted: Bool
    var onSelectFolderTapped: () -> Void

    @State private var isOrbHovered: Bool = false
    @State private var isButtonHovered: Bool = false

    private var isHighlighted: Bool {
        isOrbHovered || isTargeted
    }

    var body: some View {
        ZStack {
            // MARK: - Capa de Luces de Fondo (Figma: dos círculos 591x591 con blur)
            backgroundLights

            // MARK: - Composición Central con Capas Z Específicas
            // Centro del orbe como ancla de referencia para evitar saltos de layout
            VStack(spacing: 0) {
                // 1. Título Superior (Posición fija: exactamente a 50pt del orbe)
                Text("ARRASTRA TUS VÍDEOS AQUÍ")
                    .screenTitleStyle()
                    .zIndex(5) // Encima del destello

                Spacer()
                    .frame(height: AppTheme.Dimensions.titleToOrbSpacing)

                // 2. Zona Central del Orbe y Destello
                ZStack {
                    // Sombra / Destello Neón: Detrás del orbe, pero se expande hacia abajo por ENCIMA del botón
                    OrbNeonGlowView(
                        diameter: AppTheme.Dimensions.orbDiameter,
                        isHighlighted: isHighlighted
                    )
                    .zIndex(2) // Encima del botón (zIndex 1), detrás del orbe (zIndex 3)

                    // Contenedor Glass del Orbe (222x222 pt)
                    GlowingOrbView(
                        diameter: AppTheme.Dimensions.orbDiameter,
                        isHighlighted: isHighlighted
                    )
                    .contentShape(Circle())
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isOrbHovered = hovering
                        }
                    }
                    .zIndex(3) // Encima del destello
                }
                .frame(
                    width: AppTheme.Dimensions.orbDiameter,
                    height: AppTheme.Dimensions.orbDiameter
                )

                Spacer()
                    .frame(height: AppTheme.Dimensions.orbToButtonSpacing)

                // 3. Botón "SELECCIONAR CARPETA" (Posición fija: exactamente a 41pt del orbe)
                selectFolderButton
                    .zIndex(1) // Detrás del destello neón que cae sobre su parte superior
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    // MARK: - Subviews
    private var selectFolderButton: some View {
        Button(action: onSelectFolderTapped) {
            Text("SELECCIONAR CARPETA")
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
                    color: isButtonHovered ? AppTheme.Colors.neonPurple.opacity(0.40) : Color.clear,
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
    }

    private var backgroundLights: some View {
        ZStack {
            // Luz superior izquierda (Figma: W 591, H 591, #2E3C6A) al 40%
            Circle()
                .fill(AppTheme.Colors.backgroundLight.opacity(0.40))
                .frame(
                    width: AppTheme.Dimensions.backgroundLightDiameter,
                    height: AppTheme.Dimensions.backgroundLightDiameter
                )
                .blur(radius: AppTheme.Dimensions.backgroundLightBlur)
                .offset(x: -240, y: -190)

            // Luz inferior derecha (Figma: W 591, H 591, #2E3C6A) al 40%
            Circle()
                .fill(AppTheme.Colors.backgroundLight.opacity(0.40))
                .frame(
                    width: AppTheme.Dimensions.backgroundLightDiameter,
                    height: AppTheme.Dimensions.backgroundLightDiameter
                )
                .blur(radius: AppTheme.Dimensions.backgroundLightBlur)
                .offset(x: 260, y: 190)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.spaceBlack
            .ignoresSafeArea()
        DropzoneView(isTargeted: .constant(false), onSelectFolderTapped: {})
    }
    .frame(width: AppTheme.Dimensions.windowWidth, height: AppTheme.Dimensions.windowHeight)
}
