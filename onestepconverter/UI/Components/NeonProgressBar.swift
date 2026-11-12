//
//  NeonProgressBar.swift
//  OneStepConverter
//
//  Barra de progreso redondeada con estilo neón púrpura.
//  Se implementará completamente en Fase 2.
//

import SwiftUI

/// Barra de progreso con track oscuro y relleno púrpura neón.
struct NeonProgressBar: View {
    var progress: Double = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track oscuro
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.progressBarHeight / 2)
                    .fill(AppTheme.Colors.glassSurface)
                    .frame(height: AppTheme.Dimensions.progressBarHeight)

                // Relleno púrpura neón
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.progressBarHeight / 2)
                    .fill(AppTheme.Gradients.neonAccent)
                    .frame(
                        width: geometry.size.width * CGFloat(min(max(progress, 0), 1)),
                        height: AppTheme.Dimensions.progressBarHeight
                    )
            }
        }
        .frame(height: AppTheme.Dimensions.progressBarHeight)
    }
}

#Preview {
    NeonProgressBar(progress: 0.65)
        .padding()
        .frame(width: 300)
        .background(AppTheme.Colors.spaceBlack)
}

