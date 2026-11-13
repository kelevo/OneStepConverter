//
//  DropzoneView.swift
//  OneStepConverter
//
//  Vista principal de arrastrar y soltar archivos (pantalla de inicio e ingesta).
//  Soporta estados idle, draggingOver, importing, limitExceeded y confirmación con configuración (Fase 4).
//

import SwiftUI
import UniformTypeIdentifiers

struct DropzoneView: View {
    @Bindable var viewModel: QueueViewModel

    @State private var isPrimaryButtonHovered: Bool = false
    @State private var isCancelButtonHovered: Bool = false
    @State private var isDropTargeted: Bool = false

    var body: some View {
        ZStack {
            // MARK: - Capa de Luces de Fondo (Figma: dos círculos 591x591 con blur)
            backgroundLights

            // MARK: - Composición Central
            VStack(spacing: 0) {
                // 1. Título Superior Dinámico (Posición fija: exactamente a 58pt del orbe)
                headerTitle
                    .zIndex(5)

                Spacer()
                    .frame(height: AppTheme.Dimensions.titleToOrbSpacing)

                // 2. Zona Central Activa de Drag & Drop
                activeDropArea
                    .zIndex(3)

                // 3. Fila de Opciones en Modo Confirmación (ConfirmarCompresion_2.png)
                if viewModel.uiState == .readyToConvert {
                    Spacer()
                        .frame(height: 24)

                    optionsRow
                        .zIndex(2)

                    Spacer()
                        .frame(height: 24)
                } else {
                    Spacer()
                        .frame(height: AppTheme.Dimensions.orbToButtonSpacing)
                }

                // 4. Botonera Inferior Reactiva
                bottomControls
                    .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    // MARK: - Header Title Dinámico
    private var headerTitle: some View {
        Text(currentTitleText)
            .screenTitleStyle()
            .foregroundStyle(
                viewModel.uiState == .limitExceeded
                    ? AppTheme.Colors.errorRed
                    : AppTheme.Colors.textPrimary
            )
            .animation(.easeInOut(duration: 0.25), value: viewModel.uiState)
    }

    private var currentTitleText: String {
        switch viewModel.uiState {
        case .limitExceeded:
            return "MÁXIMO 40 VIDEOS"
        case .importing:
            return "AGREGANDO VIDEOS, ESPERA UN MOMENTO"
        case .idle, .draggingOver, .readyToConvert:
            return "ARRASTRA TUS VÍDEOS AQUÍ"
        }
    }

    // MARK: - Zona Central Activa (Orbe + Resplandor + Receptor de Drop)
    private var activeDropArea: some View {
        ZStack {
            // Resplandor Neón en Bucle (Breathing Glow con acento dinámico y diámetro proporcional)
            OrbNeonGlowView(
                diameter: currentOrbDiameter,
                accentColor: currentAccentColor,
                isTargeted: isGlowingIntensified
            )
            .zIndex(2)

            // Contenedor Glass del Orbe (222x222 pt en idle, 180x180 pt en confirmación)
            GlowingOrbView(
                diameter: currentOrbDiameter,
                contentType: currentOrbContent,
                accentColor: currentAccentColor,
                isHighlighted: isGlowingIntensified
            )
            .contentShape(Circle())
            .zIndex(3)
        }
        .frame(
            width: AppTheme.Dimensions.dropzoneActiveWidth,
            height: viewModel.uiState == .readyToConvert ? 210 : AppTheme.Dimensions.dropzoneActiveHeight
        )
        .contentShape(Rectangle())
        .onDrop(
            of: [.fileURL],
            isTargeted: $isDropTargeted,
            perform: { providers in
                handlePerformDrop(providers: providers)
            }
        )
        .onChange(of: isDropTargeted) { _, targeted in
            handleDropTargetChange(targeted)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.uiState)
    }

    private var currentOrbDiameter: CGFloat {
        viewModel.uiState == .readyToConvert
            ? AppTheme.Dimensions.confirmOrbDiameter
            : AppTheme.Dimensions.orbDiameter
    }

    // MARK: - Fila Horizontal de Opciones (ConfirmarCompresion_2.png)
    private var optionsRow: some View {
        HStack(spacing: AppTheme.Dimensions.optionsSpacing) {
            // 1. Switch "Comprimir"
            HStack(spacing: 8) {
                Text("Comprimir")
                    .font(AppTheme.Typography.optionLabelFontFallback)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Toggle("", isOn: $viewModel.options.shouldCompress)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(AppTheme.Colors.switchActive)
            }

            // 2. Switch "Modo privado"
            HStack(spacing: 8) {
                Text("Modo privado")
                    .font(AppTheme.Typography.optionLabelFontFallback)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Toggle("", isOn: $viewModel.options.isPrivateMode)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(AppTheme.Colors.switchActive)
            }

            // 3. Selector "Formato" (Cápsula Blanca + Menú)
            HStack(spacing: 8) {
                Text("Formato")
                    .font(AppTheme.Typography.optionLabelFontFallback)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Menu {
                    ForEach(OutputFormat.allCases) { format in
                        Button(action: {
                            viewModel.options.outputFormat = format
                        }) {
                            HStack {
                                Text(format.rawValue)
                                if viewModel.options.outputFormat == format {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.options.outputFormat.rawValue)
                            .font(AppTheme.Typography.formatPickerFontFallback)
                            .foregroundStyle(AppTheme.Colors.formatCapsuleText)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.formatCapsuleText)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(AppTheme.Colors.formatCapsuleBackground)
                    .clipShape(Capsule())
                }
                .menuStyle(.borderlessButton)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Botonera Inferior
    @ViewBuilder
    private var bottomControls: some View {
        if viewModel.uiState == .readyToConvert {
            // Estado Confirmar Lote (ConfirmarCompresion_2.png): Dos cápsulas (CANCELAR + COMPRIMIR Y CONVERTIR)
            HStack(spacing: 16) {
                // Botón izquierdo "CANCELAR" (Cápsula roja #7F0909)
                Button(action: {
                    viewModel.cancelBatch()
                }) {
                    Text("CANCELAR")
                        .font(AppTheme.Typography.buttonFontFallback)
                        .tracking(AppTheme.Typography.buttonTracking)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .frame(
                            width: AppTheme.Dimensions.confirmCancelButtonWidth,
                            height: AppTheme.Dimensions.buttonHeight
                        )
                        .background(
                            isCancelButtonHovered
                                ? AppTheme.Colors.cancelDarkRedHover
                                : AppTheme.Colors.cancelDarkRed
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(
                            color: isCancelButtonHovered
                                ? AppTheme.Colors.cancelDarkRedGlow
                                : Color.clear,
                            radius: 12
                        )
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius))
                .scaleEffect(isCancelButtonHovered ? 1.02 : 1.0)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isCancelButtonHovered = hovering
                    }
                }

                // Botón derecho "COMPRIMIR Y CONVERTIR" (o "CONVERTIR")
                Button(action: {
                    viewModel.startConversion()
                }) {
                    Text(viewModel.options.shouldCompress ? "COMPRIMIR Y CONVERTIR" : "CONVERTIR")
                        .font(AppTheme.Typography.buttonFontFallback)
                        .tracking(AppTheme.Typography.buttonTracking)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .frame(
                            width: AppTheme.Dimensions.confirmConvertButtonWidth,
                            height: AppTheme.Dimensions.buttonHeight
                        )
                        .background(
                            isPrimaryButtonHovered
                                ? AppTheme.Colors.buttonBackground.opacity(0.95)
                                : AppTheme.Colors.buttonBackground
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius)
                                .stroke(
                                    isPrimaryButtonHovered
                                        ? Color.white.opacity(0.35)
                                        : AppTheme.Colors.glowBorder,
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isPrimaryButtonHovered
                                ? AppTheme.Colors.neonPurple.opacity(0.40)
                                : Color.clear,
                            radius: 12
                        )
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius))
                .scaleEffect(isPrimaryButtonHovered ? 1.02 : 1.0)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPrimaryButtonHovered = hovering
                    }
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            // Estado estándar: "SELECCIONAR CARPETA"
            Button(action: {
                viewModel.openFolderPicker()
            }) {
                Text("SELECCIONAR CARPETA")
                    .font(AppTheme.Typography.buttonFontFallback)
                    .tracking(AppTheme.Typography.buttonTracking)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .frame(
                        width: AppTheme.Dimensions.buttonWidth,
                        height: AppTheme.Dimensions.buttonHeight
                    )
                    .background(
                        isPrimaryButtonHovered
                            ? AppTheme.Colors.buttonBackground.opacity(0.95)
                            : AppTheme.Colors.buttonBackground
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius)
                            .stroke(
                                isPrimaryButtonHovered
                                    ? Color.white.opacity(0.35)
                                    : AppTheme.Colors.glowBorder,
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isPrimaryButtonHovered ? AppTheme.Colors.neonPurple.opacity(0.40) : Color.clear,
                        radius: 12
                    )
            }
            .buttonStyle(.plain)
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.Dimensions.capsuleCornerRadius))
            .disabled(viewModel.uiState == .importing)
            .opacity(viewModel.uiState == .importing ? 0.40 : 1.0)
            .scaleEffect(isPrimaryButtonHovered && viewModel.uiState != .importing ? 1.02 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isPrimaryButtonHovered = hovering
                }
            }
        }
    }

    // MARK: - Estado Visual Derivado
    private var currentOrbContent: OrbContentType {
        switch viewModel.uiState {
        case .idle:
            return .uploadArrow
        case .draggingOver, .importing:
            return .addingIcon
        case .readyToConvert:
            return .counter(viewModel.items.count)
        case .limitExceeded:
            return viewModel.items.isEmpty ? .uploadArrow : .counter(viewModel.items.count)
        }
    }

    private var currentAccentColor: Color {
        viewModel.uiState == .limitExceeded
            ? AppTheme.Colors.errorRed
            : AppTheme.Colors.neonPurple
    }

    private var isGlowingIntensified: Bool {
        viewModel.uiState == .draggingOver || viewModel.uiState == .importing || isDropTargeted
    }

    // MARK: - Manejo de Drag & Drop
    private func handleDropTargetChange(_ targeted: Bool) {
        guard viewModel.uiState != .importing else { return }

        if targeted {
            if viewModel.uiState != .limitExceeded {
                viewModel.uiState = .draggingOver
            }
        } else {
            if viewModel.uiState == .draggingOver {
                viewModel.uiState = viewModel.items.isEmpty ? .idle : .readyToConvert
            }
        }
    }

    private func handlePerformDrop(providers: [NSItemProvider]) -> Bool {
        guard viewModel.uiState != .importing else { return false }
        guard !providers.isEmpty else { return false }

        Task {
            var urls: [URL] = []
            for provider in providers {
                if let url = await extractURL(from: provider) {
                    urls.append(url)
                }
            }
            await viewModel.ingestURLs(urls)
        }

        return true
    }

    private func extractURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    continuation.resume(returning: url)
                }
            } else {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let url = item as? URL {
                        continuation.resume(returning: url)
                    } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }

    // MARK: - Luces de Fondo
    private var backgroundLights: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.backgroundLight.opacity(0.40))
                .frame(
                    width: AppTheme.Dimensions.backgroundLightDiameter,
                    height: AppTheme.Dimensions.backgroundLightDiameter
                )
                .blur(radius: AppTheme.Dimensions.backgroundLightBlur)
                .offset(x: -240, y: -190)

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
    DropzoneView(viewModel: QueueViewModel())
}
