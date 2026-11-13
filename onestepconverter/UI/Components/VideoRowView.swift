//
//  VideoRowView.swift
//  OneStepConverter
//
//  Fila individual de video en la cola de conversión (Fiel a Convirtiendo_2.png).
//

import SwiftUI

struct VideoRowView: View {
    let item: VideoItem
    let index: Int
    let isPrivateMode: Bool
    let shouldCompress: Bool
    var onCancel: () -> Void

    @State private var isCancelHovered: Bool = false

    private var isQueued: Bool {
        item.status == .queued || item.status == .ready
    }

    private var isActive: Bool {
        item.status == .converting
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                // 1. Orbe izquierdo de video (44 x 44 pt)
                leftVideoOrb

                // 2. Información del archivo (Título + Metadatos)
                VStack(alignment: .leading, spacing: 3) {
                    // Título (enmascarado en modo privado)
                    Text(displayTitle)
                        .font(Font.custom("Inter-Regular_SemiBold", size: 14))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)

                    // Subtítulo de metadatos enriquecidos
                    metadataLine
                }

                Spacer()

                // 3. Botón de cancelación individual (28 x 28 pt)
                if item.status == .converting || isQueued {
                    cancelButton
                } else if item.status == .completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.Colors.neonPurpleLight)
                }
            }

            // 4. Barra de progreso individual delgada (4 pt)
            NeonProgressBar(
                progress: item.progress,
                height: AppTheme.Dimensions.progressBarHeight
            )
            .opacity(isQueued ? 0.30 : 1.0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    // MARK: - Subviews

    private var displayTitle: String {
        if isPrivateMode {
            return "Video \(index + 1)"
        } else {
            return item.fileName
        }
    }

    private var leftVideoOrb: some View {
        ZStack {
            // Fondo orbe púrpura con borde
            Circle()
                .fill(
                    isActive
                        ? AppTheme.Colors.glassOrbFill.opacity(0.8)
                        : AppTheme.Colors.buttonBackground.opacity(0.6)
                )
                .frame(width: 44, height: 44)

            Circle()
                .stroke(
                    isActive
                        ? AppTheme.Colors.neonPurpleLight.opacity(0.60)
                        : Color.white.opacity(0.12),
                    lineWidth: 1
                )
                .frame(width: 44, height: 44)

            // Ícono de video centrado
            Image("IconoVideoFigma")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.white)
        }
        .shadow(
            color: isActive ? AppTheme.Colors.neonPurple.opacity(0.45) : Color.clear,
            radius: 8
        )
        .opacity(isQueued ? 0.35 : 1.0)
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

    private var cancelButton: some View {
        Button(action: onCancel) {
            ZStack {
                Circle()
                    .fill(
                        isCancelHovered
                            ? AppTheme.Colors.buttonBackground.opacity(0.95)
                            : AppTheme.Colors.glassSurfaceTranslucent
                    )
                    .frame(width: 28, height: 28)

                Circle()
                    .stroke(
                        isCancelHovered ? Color.white.opacity(0.35) : AppTheme.Colors.glowBorder,
                        lineWidth: 1
                    )
                    .frame(width: 28, height: 28)

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
        .scaleEffect(isCancelHovered ? 1.08 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isCancelHovered = hovering
            }
        }
    }
}

