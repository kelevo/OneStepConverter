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
        let effectiveCompress = item.shouldApplyCompression(userOption: options.shouldCompress)

        // Estimación inicial del tamaño de salida (videos < 300MB no se comprimen)
        let initialEstimate: Int64 = {
            if options.outputFormat == .mp3 {
                // ~128 kbps * duración
                return Int64(item.durationSeconds * (16000))
            } else if effectiveCompress {
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
                    if effectiveCompress {
                        projectedBytes = Int64(Double(size) / progress)
                    } else {
                        // En modo conversión pura (remux o sin compresión), no inflar la estimación por encima del original
                        projectedBytes = min(item.fileSizeBytes, Int64(Double(size) / progress))
                    }
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
                    throw VideoProcessingError.processFailed(process.terminationStatus, logCapture.log.suffix(2000).description)
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

        // Regla de negocio: la regla de los 300MB aplica exclusivamente a la compresión.
        // Si el usuario eligió CONVERTIR (shouldCompress == false), se convierten todos los videos sin filtro de 300MB.
        let shouldCompress = item.shouldApplyCompression(userOption: options.shouldCompress)

        switch options.outputFormat {
        case .mp4:
            // Mapeo seguro de streams: primer video, primer audio (si existe), descartando subtítulos (teletexto DVB, etc.) y datos
            // Normalización de timestamps con -avoid_negative_ts make_zero para evitar pantallas negras o desincronización
            args.append(contentsOf: [
                "-map", "0:v:0",
                "-map", "0:a:0?",
                "-sn",
                "-dn",
                "-avoid_negative_ts", "make_zero"
            ])

            if shouldCompress {
                // Modo equilibrado / alta compresión compatible universal (para videos >= 300MB)
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
                // Modo Conversión Pura: CERO AUMENTO DE TAMAÑO
                let canCopyVideo = isMp4CompatibleVideoCodec(item.videoCodec)
                let hasAudio = !item.audioCodec.isEmpty && item.audioCodec.lowercased() != "none"
                let canCopyAudio = !hasAudio || isMp4CompatibleAudioCodec(item.audioCodec)
                let needsHevcTag = isHevcVideoCodec(item.videoCodec)

                if canCopyVideo && canCopyAudio {
                    // Remux instantáneo fiel al script de referencia: ffmpeg -i input.mov -c copy output.mp4
                    args.append(contentsOf: ["-c", "copy"])
                    if needsHevcTag {
                        args.append(contentsOf: ["-tag:v", "hvc1"])
                    }
                    args.append(contentsOf: ["-movflags", "+faststart"])
                } else if canCopyVideo && !canCopyAudio {
                    // Video compatible intacto (0% cambio de peso de video), normalizando solo audio incompatible (ej. MP2, AC3, PCM) a AAC
                    args.append(contentsOf: ["-c:v", "copy"])
                    if needsHevcTag {
                        args.append(contentsOf: ["-tag:v", "hvc1"])
                    }
                    args.append(contentsOf: [
                        "-c:a", "aac",
                        "-b:a", "128k",
                        "-movflags", "+faststart"
                    ])
                } else {
                    // Formato fuente obsoleto no compatible con MP4 (ej. MPEG-2 de archivos .ts): transcodificación segura sin inflar peso
                    var transcodeArgs = [
                        "-c:v", "libx264",
                        "-preset", "fast",
                        "-crf", "26",
                        "-pix_fmt", "yuv420p",
                        "-c:a", "aac",
                        "-b:a", "128k",
                        "-movflags", "+faststart"
                    ]
                    // Techo de bitrate basado en el archivo original para garantizar que nunca aumente
                    if item.durationSeconds > 0 {
                        let originalBitrateKbps = Int((Double(item.fileSizeBytes) * 8.0) / (item.durationSeconds * 1000.0))
                        if originalBitrateKbps > 100 {
                            let targetBitrateKbps = max(100, Int(Double(originalBitrateKbps) * 0.88))
                            transcodeArgs.append(contentsOf: [
                                "-b:v", "\(targetBitrateKbps)k",
                                "-maxrate", "\(targetBitrateKbps)k",
                                "-bufsize", "\(targetBitrateKbps * 2)k"
                            ])
                        }
                    }
                    args.append(contentsOf: transcodeArgs)
                }
            }

        case .mov:
            // Mapeo seguro de streams y normalización de timestamps para QuickTime MOV
            args.append(contentsOf: [
                "-map", "0:v:0",
                "-map", "0:a:0?",
                "-sn",
                "-dn",
                "-avoid_negative_ts", "make_zero"
            ])

            if shouldCompress {
                args.append(contentsOf: [
                    "-c:v", "libx264",
                    "-preset", "medium",
                    "-crf", "26",
                    "-pix_fmt", "yuv420p",
                    "-c:a", "aac",
                    "-b:a", "128k"
                ])
            } else {
                // Modo Conversión a MOV sin compresión: remux instantáneo para fuentes compatibles
                let canCopyVideo = isMovCompatibleVideoCodec(item.videoCodec)
                let hasAudio = !item.audioCodec.isEmpty && item.audioCodec.lowercased() != "none"
                let canCopyAudio = !hasAudio || isMovCompatibleAudioCodec(item.audioCodec)

                if canCopyVideo && canCopyAudio {
                    args.append(contentsOf: ["-c", "copy"])
                } else if canCopyVideo && !canCopyAudio {
                    args.append(contentsOf: [
                        "-c:v", "copy",
                        "-c:a", "aac",
                        "-b:a", "128k"
                    ])
                } else {
                    var transcodeArgs = [
                        "-c:v", "libx264",
                        "-preset", "fast",
                        "-crf", "26",
                        "-pix_fmt", "yuv420p",
                        "-c:a", "aac",
                        "-b:a", "128k"
                    ]
                    if item.durationSeconds > 0 {
                        let originalBitrateKbps = Int((Double(item.fileSizeBytes) * 8.0) / (item.durationSeconds * 1000.0))
                        if originalBitrateKbps > 100 {
                            transcodeArgs.append(contentsOf: [
                                "-maxrate", "\(originalBitrateKbps)k",
                                "-bufsize", "\(originalBitrateKbps * 2)k"
                            ])
                        }
                    }
                    args.append(contentsOf: transcodeArgs)
                }
            }

        case .mp3:
            // Extracción pura de audio MP3 descartando video, subtítulos y datos
            args.append(contentsOf: [
                "-map", "0:a:0?",
                "-vn",
                "-sn",
                "-dn",
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

    // MARK: - Helpers de Compatibilidad de Códecs

    /// Códecs de video compatibles para copia directa en contenedor MP4
    private func isMp4CompatibleVideoCodec(_ codec: String) -> Bool {
        let c = codec.lowercased()
        return c.contains("h264") || c.contains("avc") ||
               c.contains("hevc") || c.contains("h265") ||
               c.contains("mpeg4") || c.contains("mp4v")
    }

    /// Determina si el códec de video es HEVC / H.265 (requiere -tag:v hvc1 en MP4 para Apple/QuickTime)
    private func isHevcVideoCodec(_ codec: String) -> Bool {
        let c = codec.lowercased()
        return c.contains("hevc") || c.contains("h265") || c.contains("hvc1") || c.contains("hev1")
    }

    /// Códecs de audio compatibles para copia directa en contenedor MP4 (reproducción universal garantizada)
    private func isMp4CompatibleAudioCodec(_ codec: String) -> Bool {
        let c = codec.lowercased()
        return c.contains("aac") || c.contains("mp4a") || c.contains("mp3")
    }

    /// Códecs de video compatibles para copia directa en contenedor MOV (QuickTime)
    private func isMovCompatibleVideoCodec(_ codec: String) -> Bool {
        let c = codec.lowercased()
        return c.contains("h264") || c.contains("avc") ||
               c.contains("hevc") || c.contains("h265") ||
               c.contains("prores") || c.contains("apple prores") ||
               c.contains("mpeg4") || c.contains("jpeg") || c.contains("mjpeg")
    }

    /// Códecs de audio compatibles para copia directa en contenedor MOV (QuickTime)
    private func isMovCompatibleAudioCodec(_ codec: String) -> Bool {
        let c = codec.lowercased()
        return c.contains("aac") || c.contains("mp3") ||
               c.contains("pcm") || c.contains("alac") ||
               c.contains("ac3") || c.contains("eac3")
    }
}
