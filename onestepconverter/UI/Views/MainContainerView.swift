//
//  MainContainerView.swift
//  OneStepConverter
//
//  Vista raíz que orquesta los estados de la app.
//  Fase 1: Muestra el fondo espacial con el orbe de subida como verificación visual.
//

import SwiftUI

struct MainContainerView: View {
    var body: some View {
        ZStack {
            // Fondo espacial de degradado profundo
            AppTheme.Gradients.mainBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Título integrado en lugar de barra de título nativa
                Text("OneStepConverter")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                Spacer()

                // Título de pantalla
                Text("ARRASTRA TUS VÍDEOS AQUÍ")
                    .screenTitleStyle()
                    .padding(.bottom, 32)

                // Orbe central con ícono de subida
                GlowingOrbView.uploadOrb

                Spacer()

                // Botón cápsula placeholder
                Text("SELECCIONAR CARPETA")
                    .font(AppTheme.Typography.buttonFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.glassSurfaceTranslucent)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius)
                            .stroke(AppTheme.Colors.glowBorder, lineWidth: 1)
                    )
                    .padding(.bottom, 40)
            }
        }
        .frame(
            width: AppTheme.Dimensions.windowWidth,
            height: AppTheme.Dimensions.windowHeight
        )
    }
}

#Preview {
    MainContainerView()
}

