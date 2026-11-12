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
        ZStack {
            // Fondo espacial de degradado profundo
            AppTheme.Gradients.mainBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header superior integrado compartido
                headerBar

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
                .transition(.opacity)
            }
        }
        .frame(
            width: AppTheme.Dimensions.windowWidth,
            height: AppTheme.Dimensions.windowHeight
        )
    }

    // MARK: - Subviews
    private var headerBar: some View {
        Text("OneStepConverter")
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(AppTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }

    // MARK: - Actions
    private func handleSelectFolder() {
        print("📁 [OneStepConverter] Acción disparada: Seleccionar carpeta")
        // TODO: En Fase 3 se integrará NSOpenPanel y lectura de archivos
    }
}

#Preview {
    MainContainerView()
}
