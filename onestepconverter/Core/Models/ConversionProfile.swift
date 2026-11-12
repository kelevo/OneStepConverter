//
//  ConversionProfile.swift
//  OneStepConverter
//
//  Perfiles de conversión (Equilibrado CRF 26, Máxima Compresión, Solo MP4).
//  Se implementará completamente en Fase 2.
//

import Foundation

/// Perfiles de compresión disponibles para la conversión de video.
enum ConversionProfile: String, CaseIterable {
    case balanced     // libx264 -crf 26 -preset medium
    case maxCompress  // libx264 -crf 28 -preset slow
    case remuxOnly    // -c copy (solo cambiar contenedor)
    // TODO: Fase 2 — Agregar parámetros FFmpeg por perfil
}

