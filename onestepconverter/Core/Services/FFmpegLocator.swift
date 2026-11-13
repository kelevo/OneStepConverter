//
//  FFmpegLocator.swift
//  OneStepConverter
//
//  Localiza los binarios de ffmpeg y ffprobe en el Bundle o en el sistema.
//

import Foundation

nonisolated enum FFmpegLocator {
    /// Rutas estándar de búsqueda para binarios en macOS
    private static let candidatePaths = [
        "/opt/homebrew/bin", // Apple Silicon Homebrew
        "/usr/local/bin",    // Intel Homebrew / Standard
        "/usr/bin"
    ]

    /// Resuelve la ruta absoluta del binario `ffmpeg`
    static func locateFFmpeg() -> String? {
        locateBinary(named: "ffmpeg")
    }

    /// Resuelve la ruta absoluta del binario `ffprobe`
    static func locateFFprobe() -> String? {
        locateBinary(named: "ffprobe")
    }

    private static func locateBinary(named name: String) -> String? {
        let fileManager = FileManager.default

        // 1. Verificar dentro del Bundle de la aplicación (Contents/Resources)
        if let bundlePath = Bundle.main.path(forResource: name, ofType: nil),
           fileManager.isExecutableFile(atPath: bundlePath) {
            return bundlePath
        }

        // 2. Verificar rutas estándar del sistema
        for directory in candidatePaths {
            let fullPath = "\(directory)/\(name)"
            if fileManager.isExecutableFile(atPath: fullPath) {
                return fullPath
            }
        }

        return nil
    }
}
