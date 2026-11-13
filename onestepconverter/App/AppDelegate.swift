//
//  AppDelegate.swift
//  OneStepConverter
//
//  Configuración de ciclo de vida, Dock Tile Icon e integración nativa de macOS.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Solicitar permisos de notificación nativa
        NotificationManager.shared.requestAuthorization()

        // Asignar el ícono del logo completo a tamaño 100% en el Dock Tile de macOS
        if let logoURL = Bundle.main.url(forResource: "Logo", withExtension: "png"),
           let image = NSImage(contentsOf: logoURL) {
            NSApplication.shared.applicationIconImage = image
        } else if let icnsURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                  let image = NSImage(contentsOf: icnsURL) {
            NSApplication.shared.applicationIconImage = image
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
}
