import SwiftUI
import FirebaseCore
import FirebaseMessaging

/// Main App Entry Point
@main
struct ChipDropApp: App {
    @StateObject private var chipService = ChipService.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chipService)
                .environmentObject(notificationManager)
                .preferredColorScheme(.dark)
        }
    }
}

/// App Delegate for handling push notifications and Firebase Cloud Messaging
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Firebase must be configured before any other Firebase service is used
        FirebaseApp.configure()

        // Set delegates for notifications and FCM
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Register for background fetch
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        return true
    }

    // MARK: - APNs Token Registration

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass the APNs token to Firebase — this is REQUIRED for FCM to work on iOS
        Messaging.messaging().apnsToken = deviceToken
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ APNs Device Token: \(token)")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }

    // MARK: - MessagingDelegate (FCM Token)

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅ FCM Token: \(fcmToken ?? "nil")")
        // Token is automatically used for topic subscriptions.
        // You can also store it in Firestore if you ever need targeted pushes.
    }

    // MARK: - Handle Remote Notification (Silent Push / Background Refresh)

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // When FCM delivers a push with content-available:1, this fires even in background.
        // Use it to refresh chip data so the list is fresh when the user opens the app.
        print("📩 Remote notification received: \(userInfo)")
        Task {
            await ChipService.shared.fetchLinks()
            completionHandler(.newData)
        }
    }

    // MARK: - Foreground Notification Display

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification banner even when the app is in the foreground
        completionHandler([.banner, .badge, .sound])

        // Also refresh chip data so the list updates immediately
        Task {
            await ChipService.shared.fetchLinks()
        }
    }

    // MARK: - Notification Tap

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationManager.shared.clearBadge()

        // Refresh chip data when user taps the notification
        Task {
            await ChipService.shared.fetchLinks()
        }

        completionHandler()
    }

    // MARK: - Legacy Background Fetch

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Task {
            await ChipService.shared.fetchLinks()
            completionHandler(.newData)
        }
    }
}
