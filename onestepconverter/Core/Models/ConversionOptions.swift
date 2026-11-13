//
//  ConversionOptions.swift
//  OneStepConverter
//
//  Modelo de configuración del lote previo al procesamiento (Fase 4).
//

import Foundation

/// Formato de salida soportado para la conversión
nonisolated enum OutputFormat: String, CaseIterable, Identifiable, Sendable {
    case mp4 = "MP4"
    case mov = "MOV"
    case mp3 = "MP3"

    var id: String { rawValue }

    /// Extensión de archivo correspondiente
    var fileExtension: String {
        rawValue.lowercased()
    }

    /// Indica si el formato es solo extracción/conversión de audio
    var isAudioOnly: Bool {
        self == .mp3
    }
}

/// Opciones configurables del lote de conversión
nonisolated struct ConversionOptions: Sendable, Equatable {
    /// Activa la compresión de video/audio (encendido por defecto)
    var shouldCompress: Bool

    /// Enmascara nombres de archivo en la vista de progreso como "Video 1", "Video 2" (encendido por defecto)
    var isPrivateMode: Bool

    /// Contenedor o formato de salida (.mp4 por defecto)
    var outputFormat: OutputFormat

    init(
        shouldCompress: Bool = true,
        isPrivateMode: Bool = true,
        outputFormat: OutputFormat = .mp4
    ) {
        self.shouldCompress = shouldCompress
        self.isPrivateMode = isPrivateMode
        self.outputFormat = outputFormat
    }
}

