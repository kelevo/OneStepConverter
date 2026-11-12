//
//  DropzoneView.swift
//  OneStepConverter
//
//  Vista principal de arrastrar y soltar archivos (pantalla de inicio).
//  Fiel a la referencia visual Inicio.png con micro-interacciones suaves.
//

import SwiftUI

struct DropzoneView: View {
    @Binding var isTargeted: Bool
    var onSelectFolderTapped: () -> Void

    @State private var isOrbHovered: Bool = false
    @State private var isButtonHovered: Bool = false

    private var isOrbHighlighted: Bool {
        isOrbHovered || isTargeted
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Título de la pantalla
            Text("ARRASTRA TUS VÍDEOS AQUÍ")
                .screenTitleStyle()
                .padding(.bottom, 36)

            // Orbe central interactivo
            GlowingOrbView.uploadOrb(isHighlighted: isOrbHighlighted)
                .contentShape(Circle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isOrbHovered = hovering
                    }
                }

            Spacer()

            // Botón inferior tipo cápsula
            Button(action: onSelectFolderTapped) {
                Text("SELECCIONAR CARPETA")
                    .font(AppTheme.Typography.buttonFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        isButtonHovered
                            ? AppTheme.Colors.glassSurface.opacity(0.9)
                            : AppTheme.Colors.glassSurfaceTranslucent
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                isButtonHovered
                                    ? Color.white.opacity(0.35)
                                    : AppTheme.Colors.glowBorder,
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isButtonHovered ? AppTheme.Colors.neonPurple.opacity(0.35) : Color.clear,
                        radius: 12
                    )
            }
            .buttonStyle(.plain)
            .contentShape(Capsule())
            .scaleEffect(isButtonHovered ? 1.03 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isButtonHovered = hovering
                }
            }
            .padding(.bottom, 42)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        AppTheme.Gradients.mainBackground
            .ignoresSafeArea()
        DropzoneView(isTargeted: .constant(false), onSelectFolderTapped: {})
    }
    .frame(width: AppTheme.Dimensions.windowWidth, height: AppTheme.Dimensions.windowHeight)
}

#Preview("Targeted Dragging") {
    ZStack {
        AppTheme.Gradients.mainBackground
            .ignoresSafeArea()
        DropzoneView(isTargeted: .constant(true), onSelectFolderTapped: {})
    }
    .frame(width: AppTheme.Dimensions.windowWidth, height: AppTheme.Dimensions.windowHeight)
}
