//
//  VideoProcessor.swift
//  OneStepConverter
//
//  Motor de procesamiento con FFmpeg, streaming de progreso y cálculo de ETA en tiempo real.
//

import Foundation

/// Capturador de logs de error thread-safe para Swift Concurrency
nonisolated final class ProcessLogCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = ""

    nonisolated func append(_ text: String) {
        lock.lock()
        defer { lock.unlock() }
        buffer += text
    }

    nonisolated var log: String {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }
}

enum VideoProcessingError: Error, LocalizedError {
    case ffmpegNotFound
    case processFailed(Int32, String)
    case cancelled
    case outputNotFound

    var errorDescription: String? {
        switch self {
        case .ffmpegNotFound:
            return "No se encontró el binario ffmpeg en el sistema."
        case .processFailed(let code, let msg):
            return "FFmpeg finalizó con código \(code): \(msg)"
        case .cancelled:
            return "Procesamiento cancelado por el usuario."
        case .outputNotFound:
            return "El archivo de salida generado no fue encontrado."
        }
    }
}

actor VideoProcessor {
    private var currentProcess: Process?
    private var currentTempURL: URL?
    private var isCancelled: Bool = false

    /// Procesa un VideoItem según las opciones seleccionadas y reporta progreso, ETA y tamaño proyectado.
    func process(
        item: VideoItem,
        options: ConversionOptions,
        onProgress: @Sendable @escaping (_ progress: Double, _ etaSeconds: Double?, _ estimatedBytes: Int64?) -> Void
    ) async throws -> URL {
        guard let ffmpegPath = FFmpegLocator.locateFFmpeg() else {
            throw VideoProcessingError.ffmpegNotFound
        }

        isCancelled = false
        let tempURL = item.temporaryOutputURL
        currentTempURL = tempURL

        // Eliminar residuo temporal si existiese
        try? FileManager.default.removeItem(at: tempURL)

        let arguments = buildArguments(for: item, options: options, tempURL: tempURL)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = arguments
        currentProcess = process

        let progressPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = progressPipe
        process.standardError = errorPipe

        let startTime = Date()
        let totalMicros = item.durationSeconds * 1_000_000.0

        // Estimación inicial del tamaño de salida
        let initialEstimate: Int64 = {
            if options.outputFormat == .mp3 {
                // ~128 kbps * duración
                return Int64(item.durationSeconds * (16000))
            } else if options.shouldCompress {
                // Proyección base ~35% del tamaño original para CRF 26
                return max(1024, Int64(Double(item.fileSizeBytes) * 0.35))
            } else {
                return item.fileSizeBytes
            }
        }()

        onProgress(0.0, nil, initialEstimate)

        // Configurar lector continuo de progreso
        let fileHandle = progressPipe.fileHandleForReading
        let logCapture = ProcessLogCapture()

        fileHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }

            let lines = text.components(separatedBy: .newlines)
            var currentOutTimeUs: Double?
            var currentTotalSize: Int64?

            for line in lines {
                let parts = line.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { continue }
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let val = parts[1].trimmingCharacters(in: .whitespaces)

                if key == "out_time_us", let micros = Double(val) {
                    currentOutTimeUs = micros
                } else if key == "total_size", let bytes = Int64(val) {
                    currentTotalSize = bytes
                }
            }

            if let micros = currentOutTimeUs, totalMicros > 0 {
                let rawProgress = micros / totalMicros
                let progress = min(0.99, max(0.0, rawProgress))

                let elapsed = Date().timeIntervalSince(startTime)
                var eta: Double? = nil
                if progress > 0.02 && elapsed > 1.0 {
                    let totalEst = elapsed / progress
                    eta = max(0, totalEst - elapsed)
                }

                var projectedBytes = initialEstimate
                if let size = currentTotalSize, size > 1024, progress > 0.05 {
                    projectedBytes = Int64(Double(size) / progress)
                }

                onProgress(progress, eta, projectedBytes)
            }
        }

        // Lector para captura de errores
        let errHandle = errorPipe.fileHandleForReading
        errHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8) {
                logCapture.append(str)
            }
        }

        return try await withTaskCancellationHandler {
            do {
                try process.run()
                process.waitUntilExit()

                fileHandle.readabilityHandler = nil
                errHandle.readabilityHandler = nil
                currentProcess = nil

                if isCancelled || process.terminationStatus == 15 || process.terminationStatus == 9 {
                    try? FileManager.default.removeItem(at: tempURL)
                    throw VideoProcessingError.cancelled
                }

                guard process.terminationStatus == 0 else {
                    try? FileManager.default.removeItem(at: tempURL)
                    throw VideoProcessingError.processFailed(process.terminationStatus, logCapture.log.suffix(200).description)
                }

                guard FileManager.default.fileExists(atPath: tempURL.path) else {
                    throw VideoProcessingError.outputNotFound
                }

                onProgress(1.0, 0, try? FileManager.default.attributesOfItem(atPath: tempURL.path)[.size] as? Int64)
                return tempURL
            } catch {
                fileHandle.readabilityHandler = nil
                errHandle.readabilityHandler = nil
                currentProcess = nil
                try? FileManager.default.removeItem(at: tempURL)
                throw error
            }
        } onCancel: {
            Task {
                await self.cancel()
            }
        }
    }

    /// Cancela de inmediato el proceso en ejecución y limpia los archivos temporales
    func cancel() {
        isCancelled = true
        if let proc = currentProcess, proc.isRunning {
            proc.terminate()
        }
        if let url = currentTempURL {
            try? FileManager.default.removeItem(at: url)
        }
        currentProcess = nil
        currentTempURL = nil
    }

    // MARK: - Generación de Argumentos FFmpeg
    private func buildArguments(for item: VideoItem, options: ConversionOptions, tempURL: URL) -> [String] {
        var args = [
            "-y",
            "-i", item.sourceURL.path
        ]

        switch options.outputFormat {
        case .mp4:
            if options.shouldCompress {
                // Modo equilibrado / alta compresión compatible universal
                args.append(contentsOf: [
                    "-c:v", "libx264",
                    "-preset", "medium",
                    "-crf", "26",
                    "-pix_fmt", "yuv420p",
                    "-c:a", "aac",
                    "-b:a", "128k",
                    "-movflags", "+faststart"
                ])
            } else {
                // Sin compresión: remux instantáneo si ya es compatible, o transcodificación ligera de alta fidelidad
                let isH264 = item.videoCodec.lowercased().contains("h264") || item.videoCodec.lowercased().contains("avc")
                let isAAC = item.audioCodec.lowercased().contains("aac")

                if isH264 && isAAC {
                    args.append(contentsOf: [
                        "-c", "copy",
                        "-movflags", "+faststart"
                    ])
                } else {
                    args.append(contentsOf: [
                        "-c:v", "libx264",
                        "-preset", "fast",
                        "-crf", "18",
                        "-pix_fmt", "yuv420p",
                        "-c:a", "aac",
                        "-b:a", "192k",
                        "-movflags", "+faststart"
                    ])
                }
            }

        case .mov:
            if options.shouldCompress {
                args.append(contentsOf: [
                    "-c:v", "libx264",
                    "-preset", "medium",
                    "-crf", "26",
                    "-pix_fmt", "yuv420p",
                    "-c:a", "aac",
                    "-b:a", "128k"
                ])
            } else {
                let isMovCompatible = item.originalExtension.lowercased() == "mov"
                if isMovCompatible {
                    args.append(contentsOf: ["-c", "copy"])
                } else {
                    args.append(contentsOf: [
                        "-c:v", "libx264",
                        "-preset", "fast",
                        "-crf", "18",
                        "-pix_fmt", "yuv420p",
                        "-c:a", "aac",
                        "-b:a", "192k"
                    ])
                }
            }

        case .mp3:
            // Extracción pura de audio MP3
            args.append(contentsOf: [
                "-vn",
                "-c:a", "libmp3lame",
                "-q:a", "2"
            ])
        }

        // Streaming de progreso estándar para lectura en vivo
        args.append(contentsOf: [
            "-progress", "pipe:1",
            "-nostats",
            tempURL.path
        ])

        return args
    }
}
