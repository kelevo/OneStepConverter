//
//  NeonProgressBar.swift
//  OneStepConverter
//
//  Barra de progreso redondeada neón púrpura para filas individuales y footer global.
//

import SwiftUI

struct NeonProgressBar: View {
    var progress: Double = 0.0
    var height: CGFloat = AppTheme.Dimensions.progressBarHeight

    private var clampedProgress: CGFloat {
        CGFloat(min(1.0, max(0.0, progress)))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track oscuro
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(AppTheme.Colors.glassSurface)
                    .frame(height: height)

                // Relleno neón púrpura con resplandor
                if clampedProgress > 0 {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(AppTheme.Gradients.neonAccent)
                        .frame(width: max(height, geometry.size.width * clampedProgress), height: height)
                        .shadow(
                            color: AppTheme.Colors.neonPurple.opacity(0.40),
                            radius: 4,
                            x: 0,
                            y: 0
                        )
                        .animation(.linear(duration: 0.15), value: clampedProgress)
                }
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        NeonProgressBar(progress: 0.45, height: 4)
        NeonProgressBar(progress: 0.85, height: 6)
    }
    .padding(40)
    .background(Color(hex: "#000320"))
}
