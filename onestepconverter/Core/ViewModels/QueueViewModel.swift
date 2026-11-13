//
//  QueueViewModel.swift
//  OneStepConverter
//
//  ViewModel que gestiona la ingesta, validación e inspección de videos (Fase 3).
//

import SwiftUI
import UniformTypeIdentifiers

/// Estados visuales de la Dropzone y la ingesta
enum DropzoneUIState: Equatable {
    case idle
    case draggingOver
    case importing
    case limitExceeded
    case readyToConvert
}

/// Gestiona la cola de videos a procesar, su inspección y validación de lote.
@Observable
@MainActor
final class QueueViewModel {
    // MARK: - Propiedades de Estado
    var items: [VideoItem] = []
    var uiState: DropzoneUIState = .idle

    /// Límite estricto de videos por lote
    let maxBatchLimit: Int = 40

    // MARK: - Propiedades Privadas
    private var limitExceededTimerTask: Task<Void, Never>?
    private var stateBeforeExceeded: DropzoneUIState = .idle

    /// Extensiones de video compatibles para ingesta
    private let supportedExtensions: Set<String> = [
        "mp4", "mov", "avi", "mkv", "m4v", "webm", "flv", "wmv"
    ]

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
        panel.allowedContentTypes = [
            .movie,
            .video,
            .quickTimeMovie,
            .mpeg4Movie,
            .avi
        ]

        if panel.runModal() == .OK {
            let selectedURLs = panel.urls
            Task {
                await self.ingestURLs(selectedURLs)
            }
        }
    }

    /// Vacía la cola y regresa la aplicación al estado inicial (.idle)
    func clearQueue() {
        cancelLimitExceededTimer()
        items.removeAll()
        uiState = .idle
    }

    /// Disparado al presionar "COMPRIMIR Y CONVERTIR" en la Fase 3 (reinicia a .idle)
    func startCompression() {
        clearQueue()
    }

    // MARK: - Manejo de Estado de Límite Excedido (6 segundos)

    private func triggerLimitExceeded() {
        // Guardar estado previo para restaurar con precisión
        stateBeforeExceeded = items.isEmpty ? .idle : .readyToConvert

        cancelLimitExceededTimer()
        uiState = .limitExceeded

        // Iniciar temporizador de 6 segundos exactos
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
                // Escaneo recursivo dentro de la carpeta
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
                // Archivo individual
                if isCandidateVideoFile(url) {
                    results.append(url)
                }
            }
        }

        return results
    }

    private func isCandidateVideoFile(_ url: URL) -> Bool {
        let fileName = url.lastPathComponent
        // Ignorar archivos ocultos
        if fileName.hasPrefix(".") { return false }
        // Ignorar archivos temporales generados por la app
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
                        // Archivo corrupto o no reconocido: se descarta silenciosamente
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
}
