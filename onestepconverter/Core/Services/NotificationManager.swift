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
            if let error = error {
                print("Error al solicitar permisos de notificación: \(error.localizedDescription)")
            }
        }
    }

    /// Permite que la notificación se presente en pantalla (banner + sonido) aun cuando la app esté en primer plano
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
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

    /// Dispara la notificación nativa de finalización de lote
    func sendBatchCompletedNotification(completedCount: Int, savedBytes: Int64, savedFormatted: String) {
        let content = UNMutableNotificationContent()
        content.title = "¡Proceso completado!"
        if savedBytes > 0 {
            content.body = "Todos los videos han sido procesados (\(completedCount) videos • \(savedFormatted) reducidos)."
        } else {
            content.body = "Todos los videos han sido procesados (\(completedCount) videos)."
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error al programar la notificación: \(error.localizedDescription)")
            }
        }
    }
}

