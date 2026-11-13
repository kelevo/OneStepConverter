//
//  OneStepConverterApp.swift
//  OneStepConverter
//
//  Punto de entrada de la aplicación.
//  Ventana fija 760×560 con barra de título oculta y adaptador de AppDelegate.
//

import SwiftUI

@main
struct OneStepConverterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainContainerView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 760, height: 560)
        .windowStyle(.hiddenTitleBar)
    }
}
