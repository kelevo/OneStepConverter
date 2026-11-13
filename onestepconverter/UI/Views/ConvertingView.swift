//
//  ConvertingView.swift
//  OneStepConverter
//
//  Vista de procesamiento activo con lista deslizable de videos, estimaciones en tiempo real
//  y footer de progreso global (Fiel a Convirtiendo_2.png).
//

import SwiftUI

struct ConvertingView: View {
    @Bindable var viewModel: QueueViewModel

    var body: some View {
        ZStack {
            // Fondo espacial profundo
            AppTheme.Gradients.mainBackground
                .ignoresSafeArea()

            // Luces ambientales difusas
            backgroundLights
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Título superior
                Text("CONVIRTIENDO")
                    .screenTitleStyle()
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                // Lista de videos con desvanecimiento inferior suave
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                            VideoRowView(
                                item: item,
                                index: index + 1,
                                isPrivateMode: viewModel.options.isPrivateMode,
                                shouldCompress: viewModel.options.shouldCompress,
                                onCancel: {
                                    viewModel.cancelItem(id: item.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 48)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: 0.88),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Spacer(minLength: 8)

                // Footer de Progreso Global
                globalProgressFooter
                    .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Footer de Progreso Global (Convirtiendo_2.png)
    private var globalProgressFooter: some View {
        VStack(spacing: 8) {
            // Conteo global "X de Y videos"
            Text("\(viewModel.completedCount) de \(viewModel.items.count) videos")
                .font(Font.custom("Inter-Regular_Bold", size: 17))
                .foregroundStyle(Color.white)

            // Tiempo restante total estimado
            Text(viewModel.formattedTotalRemainingTime)
                .font(Font.custom("Inter-Regular", size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)

            // Barra de progreso global (6 pt de alto)
            NeonProgressBar(
                progress: viewModel.globalProgress,
                height: AppTheme.Dimensions.globalProgressBarHeight
            )
            .padding(.horizontal, 48)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Luces Ambientales
    private var backgroundLights: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.backgroundLight.opacity(0.35))
                .frame(
                    width: AppTheme.Dimensions.backgroundLightDiameter,
                    height: AppTheme.Dimensions.backgroundLightDiameter
                )
                .blur(radius: AppTheme.Dimensions.backgroundLightBlur)
                .offset(x: -120, y: -80)

            Circle()
                .fill(AppTheme.Colors.neonPurple.opacity(0.12))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: 140, y: 100)
        }
    }
}

#Preview {
    ConvertingView(viewModel: QueueViewModel())
        .frame(width: 760, height: 532)
}
