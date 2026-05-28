import SwiftUI
import AppTrackingTransparency

/// Root navigation container
struct ContentView: View {
    @EnvironmentObject var chipService: ChipService
    @EnvironmentObject var notificationManager: NotificationManager

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .tint(.white)
        .task {
            chipService.startFirestoreListener()
            // Fetch chip links immediately — do not block content loading on permission dialogs.
            await chipService.fetchLinks()
        }
        .task {
            // Request notification permissions separately so reviewers/users can still see content
            // even if they ignore or deny the prompt.
            await notificationManager.requestPermission()
            notificationManager.scheduleDailyReminder()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Request ATT permission for ad tracking — must be shown after app is active
            requestTrackingPermission()
        }
    }

    private func requestTrackingPermission() {
        // Only prompt if status is not yet determined
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            // Small delay ensures the app is fully active before showing the prompt
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        print("✅ Tracking authorized")
                    case .denied:
                        print("❌ Tracking denied")
                    case .restricted:
                        print("⚠️ Tracking restricted")
                    case .notDetermined:
                        print("❓ Tracking not determined")
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}
