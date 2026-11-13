//
//  VideoRowView.swift
//  OneStepConverter
//
//  Fila individual de video en la cola de conversión (Fiel a Convirtiendo_2.png).
//  Sin líneas divisorias, con orbe Liquid Glass y resplandor neón idéntico al de inicio,
//  e icono de cancelar/eliminar persistente.
//

import SwiftUI

struct VideoRowView: View {
    let item: VideoItem
    let index: Int
    let isPrivateMode: Bool
    let shouldCompress: Bool
    var onCancel: () -> Void
    var onRemove: () -> Void

    @State private var isActionHovered: Bool = false

    private var isQueued: Bool {
        item.status == .queued || item.status == .ready
    }

    private var isActive: Bool {
        item.status == .converting
    }

    private var isFinished: Bool {
        item.status == .completed || item.status == .cancelled
    }

    var body: some View {
        HStack(spacing: 16) {
            // 1. Orbe izquierdo con resplandor neón idéntico al contenedor de la flecha de inicio
            leftVideoOrb

            // 2. Información del archivo (Título + Metadatos)
            VStack(alignment: .leading, spacing: 4) {
                // Título (enmascarado en modo privado)
                Text(displayTitle)
                    .font(Font.custom("Inter-Regular_SemiBold", size: 14))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)

                // Subtítulo de metadatos enriquecidos
                metadataLine
            }

            Spacer()

            // 3. Botón cancelar / eliminar (28 x 28 pt con IconoCloseFigma)
            actionButton
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
    }

    // MARK: - Orbe de Video con Resplandor Neón de Inicio (Figma)
    private var leftVideoOrb: some View {
        ZStack {
            // Resplandor neón pulsante continuo (exactamente el mismo del contenedor de flecha de inicio)
            OrbNeonGlowView(
                diameter: 44,
                accentColor: AppTheme.Colors.neonPurple,
                isTargeted: isActive
            )
            .opacity(isActive ? 1.0 : (isQueued ? 0.30 : 0.65))

            // Orbe circular Liquid Glass
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)

                Circle()
                    .fill(AppTheme.Colors.glassOrbFill.opacity(isActive ? 0.50 : 0.25))
                    .frame(width: 44, height: 44)

                // Gradiente diagonal de refracción
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.24),
                                Color.white.opacity(0.04),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                // Borde reflectivo exterior
                Circle()
                    .stroke(AppTheme.Gradients.glassStroke, lineWidth: 1.0)
                    .frame(width: 44, height: 44)

                // Ícono de cámara de video oficial Figma (IconoVideoFigma.svg)
                Image("IconoVideoFigma")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 15)
                    .foregroundStyle(Color.white)
            }
            .frame(width: 44, height: 44)
        }
        .frame(width: 44, height: 44)
        .opacity(isQueued ? 0.38 : 1.0)
    }

    // MARK: - Subviews de Metadatos

    private var displayTitle: String {
        if isPrivateMode {
            return "Video \(index)"
        } else {
            return item.fileName
        }
    }

    private var metadataLine: some View {
        HStack(spacing: 4) {
            // Formato original y peso original
            Text("\(item.originalExtension.uppercased()) - \(item.formattedFileSize)")
                .font(Font.custom("Inter-Regular", size: 12))
                .foregroundStyle(AppTheme.Colors.textSecondary)

            // Flecha y peso después de comprimir en rojo brillante
            if let compressedText = compressedSizeText {
                Text(">")
                    .font(Font.custom("Inter-Regular", size: 12))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Text(compressedText)
                    .font(Font.custom("Inter-Regular_SemiBold", size: 12))
                    .foregroundStyle(AppTheme.Colors.errorRed)
            }

            Text(" | ")
                .font(Font.custom("Inter-Regular", size: 12))
                .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.6))

            // ETA o resultado
            Text(statusDetailText)
                .font(Font.custom("Inter-Regular", size: 12))
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Text(" - ")
                .font(Font.custom("Inter-Regular", size: 12))
                .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.6))

            // Etapa actual
            Text(stageText)
                .font(Font.custom("Inter-Regular", size: 12))
                .foregroundStyle(stageColor)
        }
    }

    private var compressedSizeText: String? {
        if item.status == .completed, let actual = item.formattedActualFileSize {
            return actual
        } else if let estimated = item.formattedEstimatedFileSize {
            return estimated
        }
        return nil
    }

    private var statusDetailText: String {
        switch item.status {
        case .converting:
            return item.formattedETA
        case .completed:
            return "Completado"
        case .cancelled:
            return "Omitido"
        case .failed(let reason):
            return "Error: \(reason.prefix(25))"
        default:
            return "En espera"
        }
    }

    private var stageText: String {
        switch item.status {
        case .converting:
            return shouldCompress ? "Comprimiendo" : "Convirtiendo"
        case .completed:
            return "Completado"
        case .cancelled:
            return "Cancelado"
        case .failed:
            return "Fallido"
        default:
            return "Pendiente"
        }
    }

    private var stageColor: Color {
        switch item.status {
        case .converting:
            return AppTheme.Colors.neonPurpleLight
        case .completed:
            return Color(hex: "#10B981") // Verde esmeralda suave
        case .cancelled, .failed:
            return AppTheme.Colors.errorRed
        default:
            return AppTheme.Colors.textSecondary
        }
    }

    // MARK: - Botón Acción (Cancelar en proceso / Eliminar de lista al finalizar)
    private var actionButton: some View {
        Button(action: {
            if isFinished {
                onRemove()
            } else {
                onCancel()
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        isActionHovered
                            ? (isFinished ? AppTheme.Colors.buttonBackground.opacity(0.95) : AppTheme.Colors.cancelRed.opacity(0.85))
                            : AppTheme.Colors.glassSurfaceTranslucent
                    )
                    .frame(
                        width: AppTheme.Dimensions.cancelButtonDiameter,
                        height: AppTheme.Dimensions.cancelButtonDiameter
                    )

                Circle()
                    .stroke(
                        isActionHovered ? Color.white.opacity(0.35) : AppTheme.Colors.glowBorder,
                        lineWidth: 1
                    )
                    .frame(
                        width: AppTheme.Dimensions.cancelButtonDiameter,
                        height: AppTheme.Dimensions.cancelButtonDiameter
                    )

                Image("IconoCloseFigma")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 9, height: 9)
                    .foregroundStyle(Color.white)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .scaleEffect(isActionHovered ? 1.08 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isActionHovered = hovering
            }
        }
    }
}
