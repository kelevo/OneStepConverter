//
//  NotificationManager.swift
//  OneStepConverter
//
//  Servicio de notificaciones nativas del sistema con UserNotifications (UNUserNotificationCenter).
//

import AppKit
import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Solicita autorización al usuario para mostrar notificaciones del sistema
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Permisos de notificación de macOS concedidos.")
            } else if let error = error {
                print("⚠️ Error al solicitar permisos de notificación: \(error.localizedDescription)")
            } else {
                print("ℹ️ Permisos de notificación no autorizados por macOS. Se usará fallback nativo.")
            }
        }
    }

    /// Permite que la notificación se presente en pantalla (banner + sonido + centro de notificaciones) aun cuando la app esté en primer plano
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound, .list])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    /// Al hacer clic en la notificación, trae la app al frente
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = NSApplication.shared.windows.first(where: { $0.canBecomeKey }) ?? NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
        }
        completionHandler()
    }

    /// Dispara la notificación nativa de finalización de lote con fallback garantizado
    func sendBatchCompletedNotification(completedCount: Int, savedBytes: Int64, savedFormatted: String) {
        guard completedCount > 0 else { return }

        let title = "¡Proceso completado!"
        let body: String = {
            if savedBytes > 0 {
                return "Todos los videos han sido procesados (\(completedCount) videos • \(savedFormatted) reducidos)."
            } else {
                let unit = completedCount == 1 ? "video" : "videos"
                return "Todos los videos han sido procesados (\(completedCount) \(unit))."
            }
        }()

        // 1. Reproducir sonido nativo de confirmación de macOS de inmediato
        NSSound(named: "Glass")?.play()

        // 2. Intentar envío vía UNUserNotificationCenter
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("UNUserNotificationCenter falló: \(error.localizedDescription). Ejecutando fallback...")
                        Self.sendFallbackNotification(title: title, message: body)
                    }
                }
            } else {
                // Si no tiene permisos concedidos de UNUserNotificationCenter (común en apps ad-hoc fuera de App Store),
                // ejecutar el fallback nativo garantizado vía AppleScript
                Self.sendFallbackNotification(title: title, message: body)
            }
        }
    }

    /// Fallback nativo usando AppleScript (100% garantizado en cualquier versión de macOS y sin importar firma)
    private static func sendFallbackNotification(title: String, message: String) {
        DispatchQueue.main.async {
            let cleanTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
            let cleanMessage = message.replacingOccurrences(of: "\"", with: "\\\"")
            let scriptSource = "display notification \"\(cleanMessage)\" with title \"\(cleanTitle)\""
            if let script = NSAppleScript(source: scriptSource) {
                var errorInfo: NSDictionary?
                script.executeAndReturnError(&errorInfo)
                if let err = errorInfo {
                    print("Error en notificación fallback: \(err)")
                }
            }
        }
    }
}

