//
//  VideoInspector.swift
//  OneStepConverter
//
//  Wrapper asíncrono de ffprobe para extracción y validación de metadatos de video.
//

import Foundation

enum VideoInspectionError: Error {
    case ffprobeNotFound
    case processFailed(String)
    case notAVideo
    case parsingFailed
}

struct VideoMetadata: Sendable {
    let durationSeconds: Double
    let videoCodec: String
    let audioCodec: String
    let fileSizeBytes: Int64
}

nonisolated struct FFprobeStream: Decodable, Sendable {
    let codec_type: String?
    let codec_name: String?
    let duration: String?
}

nonisolated struct FFprobeFormat: Decodable, Sendable {
    let duration: String?
    let size: String?
}

nonisolated struct FFprobeOutput: Decodable, Sendable {
    let streams: [FFprobeStream]?
    let format: FFprobeFormat?
}

nonisolated enum VideoInspector {
    /// Inspecciona un archivo de video mediante ffprobe y retorna sus metadatos.
    /// Lanza `VideoInspectionError` si el archivo no es un video válido o no se puede inspeccionar.
    static func inspect(fileURL: URL) async throws -> VideoMetadata {
        guard let ffprobePath = FFmpegLocator.locateFFprobe() else {
            throw VideoInspectionError.ffprobeNotFound
        }

        return try await Task.detached(priority: .userInitiated) { () -> VideoMetadata in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ffprobePath)
            process.arguments = [
                "-v", "quiet",
                "-print_format", "json",
                "-show_format",
                "-show_streams",
                fileURL.path
            ]

            let stdoutPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = Pipe()

            try process.run()
            let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                throw VideoInspectionError.processFailed("Status \(process.terminationStatus)")
            }

            let decoder = JSONDecoder()
            guard let output = try? decoder.decode(FFprobeOutput.self, from: data),
                  let streams = output.streams else {
                throw VideoInspectionError.parsingFailed
            }

            // Validar que exista al menos un stream de video
            guard let videoStream = streams.first(where: { $0.codec_type == "video" }),
                  let videoCodec = videoStream.codec_name else {
                throw VideoInspectionError.notAVideo
            }

            // Obtener códec de audio si existe
            let audioCodec = streams.first(where: { $0.codec_type == "audio" })?.codec_name ?? "none"

            // Obtener duración en segundos (priorizar format.duration, luego stream.duration)
            var duration: Double = 0.0
            if let durationStr = output.format?.duration, let d = Double(durationStr) {
                duration = d
            } else if let durationStr = videoStream.duration, let d = Double(durationStr) {
                duration = d
            }

            guard duration > 0 else {
                throw VideoInspectionError.notAVideo
            }

            // Obtener tamaño del archivo
            var fileSize: Int64 = 0
            if let sizeStr = output.format?.size, let s = Int64(sizeStr) {
                fileSize = s
            } else if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                      let s = attrs[.size] as? Int64 {
                fileSize = s
            }

            return VideoMetadata(
                durationSeconds: duration,
                videoCodec: videoCodec,
                audioCodec: audioCodec,
                fileSizeBytes: fileSize
            )
        }.value
    }
}
