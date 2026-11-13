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
        etaSeconds: Double? = nil
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
    }

    /// Formato legible del tamaño (ej. "1.2 GB" o "450 MB")
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
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
}
