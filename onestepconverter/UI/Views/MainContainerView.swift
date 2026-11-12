//
//  MainContainerView.swift
//  OneStepConverter
//
//  Vista raíz que orquesta los estados de navegación de la app.
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
        ZStack(alignment: .top) {
            // Fondo espacial base absoluto (#000320)
            AppTheme.Colors.spaceBlack
                .ignoresSafeArea()

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

            // Título superior a la misma altura exacta de los semáforos de macOS
            Text("OneStepConverter")
                .font(AppTheme.Typography.windowTitleFont)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.top, 14)
                .allowsHitTesting(false)
        }
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
