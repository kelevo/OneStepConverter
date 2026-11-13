//
//  VideoItem.swift
//  OneStepConverter
//
//  Modelo que representa un archivo de video en la cola de procesamiento.
//

import Foundation

nonisolated enum VideoStatus: Equatable, Sendable {
    case queued
    case inspecting
    case ready
    case converting
    case completed
    case cancelled
    case failed(String)
}

nonisolated struct VideoItem: Identifiable, Sendable {
    let id: UUID
    let sourceURL: URL
    let fileName: String
    let originalExtension: String
    let fileSizeBytes: Int64
    let durationSeconds: Double
    let videoCodec: String
    let audioCodec: String
    var status: VideoStatus
    var progress: Double
    var etaSeconds: Double?
    var targetExtension: String
    var estimatedOutputBytes: Int64?
    var actualOutputBytes: Int64?

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        fileName: String,
        originalExtension: String,
        fileSizeBytes: Int64,
        durationSeconds: Double,
        videoCodec: String,
        audioCodec: String,
        status: VideoStatus = .ready,
        progress: Double = 0.0,
        etaSeconds: Double? = nil,
        targetExtension: String = "mp4",
        estimatedOutputBytes: Int64? = nil,
        actualOutputBytes: Int64? = nil
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.fileName = fileName
        self.originalExtension = originalExtension
        self.fileSizeBytes = fileSizeBytes
        self.durationSeconds = durationSeconds
        self.videoCodec = videoCodec
        self.audioCodec = audioCodec
        self.status = status
        self.progress = progress
        self.etaSeconds = etaSeconds
        self.targetExtension = targetExtension
        self.estimatedOutputBytes = estimatedOutputBytes
        self.actualOutputBytes = actualOutputBytes
    }

    /// URL temporal de procesamiento en la misma carpeta origen
    var temporaryOutputURL: URL {
        sourceURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(fileName)_onestep_temp.\(targetExtension)")
    }

    /// URL final tras renombrar el temporal
    var finalOutputURL: URL {
        sourceURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(fileName).\(targetExtension)")
    }

    /// Formato legible del tamaño original (ej. "1.2 GB" o "450 MB")
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }

    /// Formato legible del tamaño estimado comprimido
    var formattedEstimatedFileSize: String? {
        guard let bytes = estimatedOutputBytes, bytes > 0 else { return nil }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// Formato legible del tamaño final real comprimido
    var formattedActualFileSize: String? {
        guard let bytes = actualOutputBytes, bytes > 0 else { return nil }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// Formato legible de duración (ej. "02:45" o "1:15:30")
    var formattedDuration: String {
        let totalSeconds = Int(durationSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Formato legible en español natural del ETA restante (ej. "Restan 2 minutos", "Restan 35 segundos")
    var formattedETA: String {
        guard let seconds = etaSeconds, seconds > 0 else {
            return progress > 0 ? "Calculando..." : "En espera"
        }

        let totalSecs = Int(seconds)
        if totalSecs >= 3600 {
            let hours = totalSecs / 3600
            let minutes = (totalSecs % 3600) / 60
            return "Restan \(hours) h \(minutes) min"
        } else if totalSecs >= 60 {
            let minutes = (totalSecs + 30) / 60
            return minutes == 1 ? "Resta 1 minuto" : "Restan \(minutes) minutos"
        } else {
            return "Restan \(max(1, totalSecs)) segundos"
        }
    }
}
