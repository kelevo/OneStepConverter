//
//  QueueViewModel.swift
//  OneStepConverter
//
//  ViewModel que gestiona la ingesta, validación, orquestación de conversión y navegación (Fase 5).
//

import SwiftUI
import UniformTypeIdentifiers

/// Estados de pantalla principales de la aplicación
enum AppScreenState: Equatable {
    case dropzone
    case converting
    case completed
}

/// Estados visuales de la Dropzone y la ingesta
enum DropzoneUIState: Equatable {
    case idle
    case draggingOver
    case importing
    case limitExceeded
    case readyToConvert
}

/// Gestiona la cola de videos a procesar, su inspección, conversión con FFmpeg y estados de navegación.
@Observable
@MainActor
final class QueueViewModel {
    // MARK: - Propiedades de Estado
    var screenState: AppScreenState = .dropzone
    var items: [VideoItem] = []
    var uiState: DropzoneUIState = .idle
    var options: ConversionOptions = ConversionOptions()

    /// Límite estricto de videos por lote
    let maxBatchLimit: Int = 40

    // MARK: - Propiedades Privadas del Motor
    private let processor = VideoProcessor()
    private var conversionTask: Task<Void, Never>?
    private var currentProcessingId: UUID?
    private var limitExceededTimerTask: Task<Void, Never>?
    private var stateBeforeExceeded: DropzoneUIState = .idle

    /// Extensiones de video compatibles para ingesta (.ts incluido)
    private let supportedExtensions: Set<String> = [
        "mp4", "mov", "avi", "mkv", "m4v", "webm", "flv", "wmv", "ts", "m2ts", "mts"
    ]

    // MARK: - Propiedades Computadas de Progreso Global

    /// Índice del video actualmente en conversión
    var currentProcessingIndex: Int? {
        items.firstIndex(where: { $0.status == .converting })
    }

    /// Cantidad de videos completados exitosamente
    var completedCount: Int {
        items.filter { $0.status == .completed }.count
    }

    /// Cantidad de videos que finalizaron (completados, cancelados o fallidos)
    var processedCount: Int {
        items.filter { $0.status == .completed || $0.status == .cancelled || isFailed($0.status) }.count
    }

    /// Progreso general del lote (0.0 a 1.0)
    var globalProgress: Double {
        guard !items.isEmpty else { return 0.0 }
        let total = items.reduce(0.0) { sum, item in
            switch item.status {
            case .completed: return sum + 1.0
            case .converting: return sum + item.progress
            case .cancelled, .failed: return sum + 1.0
            default: return sum + 0.0
            }
        }
        return min(1.0, max(0.0, total / Double(items.count)))
    }

    /// Tiempo total restante estimado en minutos para el footer
    var formattedTotalRemainingTime: String {
        guard screenState == .converting else { return "0 minutos restantes" }

        // Si tenemos un item convirtiendo con ETA activo
        let activeETA = items.first(where: { $0.status == .converting })?.etaSeconds ?? 0.0

        // Estimar el tiempo de los videos pendientes en base a la duración
        let pendingDuration = items.filter { $0.status == .ready || $0.status == .queued }.reduce(0.0) { $0 + $1.durationSeconds }
        let estimatedPendingSeconds = pendingDuration * 0.40 // ratio promedio de codificación en Apple Silicon
        let totalSeconds = activeETA + estimatedPendingSeconds

        if totalSeconds <= 60 {
            return "Menos de 1 minuto restante"
        } else {
            let minutes = Int(ceil(totalSeconds / 60.0))
            return "\(minutes) minutos restantes"
        }
    }

    private func isFailed(_ status: VideoStatus) -> Bool {
        if case .failed = status { return true }
        return false
    }

    // MARK: - Ingesta de Archivos y Carpetas

    /// Ingesta una lista de URLs (archivos o carpetas) provenientes de Drag & Drop o NSOpenPanel.
    func ingestURLs(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }

        // Recolectar archivos candidatos recursivamente
        let candidateURLs = collectVideoFiles(from: urls)
        guard !candidateURLs.isEmpty else { return }

        // Validar límite estricto de 40 videos:
        // Si el total acumulado superaría el límite, rechazar TODO el lote entrante
        if items.count + candidateURLs.count > maxBatchLimit {
            triggerLimitExceeded()
            return
        }

        // Cancelar timer de error si estaba activo
        cancelLimitExceededTimer()

        // Entrar en estado de importación activa
        uiState = .importing

        // Inspeccionar candidatos en paralelo con TaskGroup
        let inspectedItems = await inspectCandidateFiles(candidateURLs)

        // Agregar los videos válidos a la lista (sin filtrar duplicados según especificación)
        items.append(contentsOf: inspectedItems)

        // Actualizar estado final de la vista
        if !items.isEmpty {
            uiState = .readyToConvert
        } else {
            uiState = .idle
        }

        // Devolver el foco a la app tras la carga de videos
        bringAppToFront()
    }

    /// Dispara el selector nativo de macOS para elegir carpeta o múltiples archivos
    func openFolderPicker() {
        guard uiState != .importing else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Selecciona una carpeta o videos (máximo 40 videos por lote)."
        panel.prompt = "Seleccionar"

        var allowedTypes: [UTType] = [
            .movie,
            .video,
            .quickTimeMovie,
            .mpeg4Movie,
            .avi,
            .mpeg2TransportStream
        ]
        if let tsType = UTType(filenameExtension: "ts") {
            allowedTypes.append(tsType)
        }
        if let mkvType = UTType(filenameExtension: "mkv") {
            allowedTypes.append(mkvType)
        }
        if let webmType = UTType(filenameExtension: "webm") {
            allowedTypes.append(webmType)
        }
        panel.allowedContentTypes = allowedTypes

        if panel.runModal() == .OK {
            let selectedURLs = panel.urls
            Task {
                await self.ingestURLs(selectedURLs)
            }
        }
    }

    /// Restaura las opciones de configuración del lote a sus valores por defecto
    func resetOptions() {
        options = ConversionOptions()
    }

    /// Vacía la cola y regresa la aplicación al estado inicial (.idle) con opciones por defecto
    func clearQueue() {
        cancelLimitExceededTimer()
        conversionTask?.cancel()
        conversionTask = nil
        currentProcessingId = nil
        items.removeAll()
        resetOptions()
        uiState = .idle
        screenState = .dropzone
    }

    /// Acción de cancelación del lote desde la vista de confirmación
    func cancelBatch() {
        clearQueue()
    }

    /// Reinicia la cola y regresa a la vista Dropzone desde la pantalla de éxito
    func convertMoreVideos() {
        clearQueue()
    }

    // MARK: - Motor de Conversión Secuencial (Fase 5)

    /// Inicia el procesamiento secuencial del lote
    func startConversion() {
        guard !items.isEmpty else { return }

        // Actualizar extensión de salida en cada item según las opciones seleccionadas
        for i in items.indices {
            items[i].targetExtension = options.outputFormat.fileExtension
            items[i].status = .queued
            items[i].progress = 0.0
            items[i].etaSeconds = nil
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            screenState = .converting
        }

        conversionTask?.cancel()
        conversionTask = Task {
            await self.processQueue()
        }
    }

    /// Procesa secuencialmente cada video de la cola (1 a la vez)
    private func processQueue() async {
        for index in items.indices {
            // Verificar si el lote completo fue cancelado
            if Task.isCancelled { break }

            // Si el ítem ya fue cancelado por el usuario previamente, omitirlo
            if items[index].status == .cancelled {
                continue
            }

            let item = items[index]
            currentProcessingId = item.id
            items[index].status = .converting

            do {
                // 1. Ejecutar FFmpeg con streaming de progreso
                let tempURL = try await processor.process(
                    item: item,
                    options: options,
                    onProgress: { [weak self] progress, eta, estBytes in
                        Task { @MainActor [weak self] in
                            guard let self = self, index < self.items.count, self.items[index].id == item.id else { return }
                            self.items[index].progress = progress
                            self.items[index].etaSeconds = eta
                            if let est = estBytes {
                                self.items[index].estimatedOutputBytes = est
                            }
                        }
                    }
                )

                // 2. Validar integridad técnica y enviar original a la Papelera de macOS
                let finalURL = try await FileTrashManager.finalizeConversion(
                    for: item,
                    tempURL: tempURL,
                    isAudioOnly: options.outputFormat == .mp3
                )

                // 3. Obtener peso final real del archivo generado
                let finalSize = (try? FileManager.default.attributesOfItem(atPath: finalURL.path)[.size] as? Int64) ?? item.fileSizeBytes

                items[index].actualOutputBytes = finalSize
                items[index].progress = 1.0
                items[index].etaSeconds = 0.0
                items[index].status = .completed

            } catch is CancellationError {
                items[index].status = .cancelled
            } catch {
                if let procErr = error as? VideoProcessingError, case .cancelled = procErr {
                    items[index].status = .cancelled
                } else {
                    items[index].status = .failed(error.localizedDescription)
                }
            }
        }

        currentProcessingId = nil

        // Devolver el foco a la app tras finalizar la cola
        bringAppToFront()

        // Transición automática a la pantalla de finalización (CompletedView)
        withAnimation(.easeInOut(duration: 0.45)) {
            self.screenState = .completed
        }
    }

    /// Cancela un ítem individual de la cola
    func cancelItem(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }

        if items[index].status == .converting {
            // Cancelar el proceso en ejecución activa
            Task {
                await processor.cancel()
            }
            items[index].status = .cancelled
        } else if items[index].status == .queued || items[index].status == .ready {
            items[index].status = .cancelled
        }
    }

    // MARK: - Manejo de Estado de Límite Excedido (6 segundos)

    private func triggerLimitExceeded() {
        stateBeforeExceeded = items.isEmpty ? .idle : .readyToConvert

        cancelLimitExceededTimer()
        uiState = .limitExceeded

        limitExceededTimerTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            guard let self = self, !Task.isCancelled else { return }
            if self.uiState == .limitExceeded {
                self.uiState = self.stateBeforeExceeded
            }
        }
    }

    private func cancelLimitExceededTimer() {
        limitExceededTimerTask?.cancel()
        limitExceededTimerTask = nil
    }

    // MARK: - Utilidades de Escaneo e Inspección

    private func collectVideoFiles(from urls: [URL]) -> [URL] {
        var results: [URL] = []
        let fileManager = FileManager.default

        for url in urls {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                continue
            }

            if isDirectory.boolValue {
                guard let enumerator = fileManager.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) else {
                    continue
                }

                for case let fileURL as URL in enumerator {
                    if isCandidateVideoFile(fileURL) {
                        results.append(fileURL)
                    }
                }
            } else {
                if isCandidateVideoFile(url) {
                    results.append(url)
                }
            }
        }

        return results
    }

    private func isCandidateVideoFile(_ url: URL) -> Bool {
        let fileName = url.lastPathComponent
        if fileName.hasPrefix(".") { return false }
        if fileName.contains("_onestep_temp") { return false }

        let ext = url.pathExtension.lowercased()
        return supportedExtensions.contains(ext)
    }

    private func inspectCandidateFiles(_ urls: [URL]) async -> [VideoItem] {
        await withTaskGroup(of: VideoItem?.self) { group in
            for fileURL in urls {
                group.addTask {
                    do {
                        let metadata = try await VideoInspector.inspect(fileURL: fileURL)
                        return VideoItem(
                            sourceURL: fileURL,
                            fileName: fileURL.deletingPathExtension().lastPathComponent,
                            originalExtension: fileURL.pathExtension.lowercased(),
                            fileSizeBytes: metadata.fileSizeBytes,
                            durationSeconds: metadata.durationSeconds,
                            videoCodec: metadata.videoCodec,
                            audioCodec: metadata.audioCodec,
                            status: .ready
                        )
                    } catch {
                        return nil
                    }
                }
            }

            var validItems: [VideoItem] = []
            for await item in group {
                if let item = item {
                    validItems.append(item)
                }
            }
            return validItems
        }
    }

    /// Pone el foco del sistema en la aplicación y activa su ventana principal
    private func bringAppToFront() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { $0.canBecomeKey }) ?? NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
