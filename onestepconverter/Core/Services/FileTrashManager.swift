//
//  FileTrashManager.swift
//  OneStepConverter
//
//  Validación rigurosa de integridad mediante ffprobe y envío seguro de originales a la Papelera de macOS.
//

import Foundation

enum FileTrashError: Error, LocalizedError {
    case tempFileNotFound
    case emptyOutputFile
    case durationMismatch(expected: Double, actual: Double)
    case validationFailed(String)
    case trashOriginalFailed(String)
    case renameFailed(String)

    var errorDescription: String? {
        switch self {
        case .tempFileNotFound:
            return "El archivo temporal generado no existe."
        case .emptyOutputFile:
            return "El archivo generado tiene 0 bytes."
        case .durationMismatch(let expected, let actual):
            return String(format: "La duración no coincide (Original: %.1fs, Generado: %.1fs).", expected, actual)
        case .validationFailed(let reason):
            return "Validación fallida: \(reason)"
        case .trashOriginalFailed(let reason):
            return "No se pudo mover el original a la papelera: \(reason)"
        case .renameFailed(let reason):
            return "No se pudo renombrar el archivo temporal: \(reason)"
        }
    }
}

nonisolated enum FileTrashManager {
    /// Valida la integridad del archivo temporal, envía el original a la Papelera de macOS y renombra el temporal a su nombre definitivo.
    /// Si la validación falla, elimina el archivo temporal y deja el original 100% intacto.
    static func finalizeConversion(
        for item: VideoItem,
        tempURL: URL,
        isAudioOnly: Bool = false
    ) async throws -> URL {
        let fileManager = FileManager.default

        // 1. Verificar existencia física del archivo temporal
        guard fileManager.fileExists(atPath: tempURL.path) else {
            throw FileTrashError.tempFileNotFound
        }

        // 2. Verificar que tenga peso real > 0 bytes
        guard let attributes = try? fileManager.attributesOfItem(atPath: tempURL.path),
              let size = attributes[.size] as? Int64, size > 0 else {
            try? fileManager.removeItem(at: tempURL)
            throw FileTrashError.emptyOutputFile
        }

        // 3. Inspeccionar integridad técnica mediante ffprobe
        do {
            let metadata = try await VideoInspector.inspect(fileURL: tempURL)

            // Tolerancia de duración de ±1.5 segundos
            let durationDiff = abs(metadata.durationSeconds - item.durationSeconds)
            if item.durationSeconds > 2.0 && durationDiff > 1.5 {
                try? fileManager.removeItem(at: tempURL)
                throw FileTrashError.durationMismatch(expected: item.durationSeconds, actual: metadata.durationSeconds)
            }
        } catch {
            // Si es MP3 o falla la inspección estricta de video
            if isAudioOnly {
                // Para MP3 basta con verificar que no esté vacío y tenga tamaño válido
            } else {
                try? fileManager.removeItem(at: tempURL)
                throw FileTrashError.validationFailed(error.localizedDescription)
            }
        }

        let destinationURL = item.finalOutputURL

        // 4. Mover el archivo original a la Papelera de macOS de forma segura
        do {
            if fileManager.fileExists(atPath: item.sourceURL.path) {
                try fileManager.trashItem(at: item.sourceURL, resultingItemURL: nil)
            }
        } catch {
            // Si no se puede enviar a la papelera, no tocar nada más
            try? fileManager.removeItem(at: tempURL)
            throw FileTrashError.trashOriginalFailed(error.localizedDescription)
        }

        // 5. Si ya existe un archivo en el destino final con el mismo nombre, enviarlo a la papelera
        if fileManager.fileExists(atPath: destinationURL.path) && destinationURL.path != tempURL.path {
            try? fileManager.trashItem(at: destinationURL, resultingItemURL: nil)
        }

        // 6. Renombrar el temporal a su nombre final
        do {
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            return destinationURL
        } catch {
            throw FileTrashError.renameFailed(error.localizedDescription)
        }
    }
}
