//
//  VideoItem.swift
//  OneStepConverter
//
//  Modelo que representa un archivo de video en la cola de procesamiento.
//  Se implementará completamente en Fase 2.
//

import Foundation

/// Modelo del archivo de video: URL, formato, tamaño, estado, progreso, ETA.
struct VideoItem: Identifiable {
    let id = UUID()
    let url: URL
    // TODO: Fase 2 — Agregar estado, progreso, metadatos FFprobe
}

