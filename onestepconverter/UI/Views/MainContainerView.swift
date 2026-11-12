//
//  MainContainerView.swift
//  OneStepConverter
//
//  Vista raíz que orquesta los estados de navegación de la app.
//  Header dedicado de 28pt con fondo #000320 continuo sin recortes.
//

import SwiftUI

/// Estados principales del ciclo de conversión.
enum AppState {
    case dropzone
    case confirmConverting
    case converting
    case completed
}

struct MainContainerView: View {
    @State private var currentState: AppState = .dropzone
    @State private var isDragTargeted: Bool = false

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

            // Contenido dinámico según el estado actual
            Group {
                switch currentState {
                case .dropzone:
                    DropzoneView(
                        isTargeted: $isDragTargeted,
                        onSelectFolderTapped: handleSelectFolder
                    )
                case .confirmConverting:
                    Text("Confirmar Lote — Próxima fase")
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                case .converting:
                    ConvertingView()
                case .completed:
                    CompletedView()
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

    // MARK: - Actions
    private func handleSelectFolder() {
        print("📁 [OneStepConverter] Acción disparada: Seleccionar carpeta")
    }
}

#Preview {
    MainContainerView()
}
