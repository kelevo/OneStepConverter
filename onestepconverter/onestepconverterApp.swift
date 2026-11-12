//
//  OneStepConverterApp.swift
//  OneStepConverter
//
//  Punto de entrada de la aplicación.
//  Ventana fija 760×560 con barra de título oculta.
//

import SwiftUI

@main
struct OneStepConverterApp: App {
    var body: some Scene {
        WindowGroup {
            MainContainerView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 760, height: 560)
        .windowStyle(.hiddenTitleBar)
    }
}
