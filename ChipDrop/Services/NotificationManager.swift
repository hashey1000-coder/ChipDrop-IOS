import Foundation
import UserNotifications
import UIKit
import FirebaseMessaging

/// Manages push notifications for new chip drops via Firebase Cloud Messaging
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    /// The FCM topic all ChipDrop users subscribe to.
    /// The Cloud Function sends to this topic when new chips are found.
    private let chipTopic = "new_chips"

    init() {
        checkAuthorization()
    }

    /// Request notification permissions and subscribe to FCM topic
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                isAuthorized = granted
            }
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                // Subscribe to FCM topic — the Cloud Function pushes to this topic
                // whenever new chip links are detected on freechipswsop.com
                subscribeToChipTopic()
                scheduleBackgroundRefresh()
            }
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    /// Subscribe this device to the FCM "new_chips" topic
    private func subscribeToChipTopic() {
        Messaging.messaging().subscribe(toTopic: chipTopic) { error in
            if let error = error {
                print("FCM topic subscription error: \(error.localizedDescription)")
            } else {
                print("✅ Subscribed to FCM topic: \(self.chipTopic)")
            }
        }
    }

    /// Unsubscribe from chip notifications (e.g. if user disables them in settings)
    func unsubscribeFromChipTopic() {
        Messaging.messaging().unsubscribe(fromTopic: chipTopic) { error in
            if let error = error {
                print("FCM unsubscribe error: \(error.localizedDescription)")
            } else {
                print("Unsubscribed from FCM topic: \(self.chipTopic)")
            }
        }
    }

    /// Check current authorization status
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Send a local notification when new chips are detected
    @MainActor
    func sendNewChipsNotification(count: Int) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "🎰 New Chips Available!"
        content.body = "\(count) new chip link\(count == 1 ? "" : "s") just dropped! Collect your free chips now before they expire."
        content.sound = .default
        content.badge = NSNumber(value: count)
        content.categoryIdentifier = "NEW_CHIPS"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "new_chips_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Schedule periodic background fetch check
    func scheduleBackgroundRefresh() {
        // Schedule a repeating local notification reminder
        let content = UNMutableNotificationContent()
        content.title = "🃏 ChipDrop Reminder"
        content.body = "New free chips may be available! Open ChipDrop to collect."
        content.sound = .default
        content.categoryIdentifier = "REMINDER"

        // Notify every 4 hours
        var dateComponents = DateComponents()
        dateComponents.hour = 4
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 14400, repeats: true)

        let request = UNNotificationRequest(
            identifier: "chip_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Schedule notification for specific time
    func scheduleDailyReminder(hour: Int = 10, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "🎲 Daily Chip Drop!"
        content.body = "Fresh chip links are waiting for you. Don't miss out on today's free chips!"
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Clear badge count
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
