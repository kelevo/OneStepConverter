//
//  MainContainerView.swift
//  OneStepConverter
//
//  Vista raíz que orquesta los estados de navegación de la app.
//  Header dedicado de 28pt con fondo #000320 continuo sin recortes.
//

import SwiftUI

struct MainContainerView: View {
    @State private var queueViewModel = QueueViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header con título centrado y fondo #000320 (Figma: 737 x 27pt)
            ZStack {
                AppTheme.Colors.spaceBlack
                    .frame(height: 28)

                Text("OneStepConverter")
                    .font(AppTheme.Typography.windowTitleFont)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .frame(height: 28)

            // Contenido dinámico según el estado actual de la máquina de estados
            Group {
                switch queueViewModel.screenState {
                case .dropzone:
                    DropzoneView(viewModel: queueViewModel)
                case .converting:
                    ConvertingView(viewModel: queueViewModel)
                case .completed:
                    CompletedView(viewModel: queueViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppTheme.Colors.spaceBlack)
        .frame(
            width: AppTheme.Dimensions.windowWidth,
            height: AppTheme.Dimensions.windowHeight
        )
    }
}

#Preview {
    MainContainerView()
}
