import SwiftUI

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
            // Request notification permissions on first launch
            await notificationManager.requestPermission()
            // Fetch chip links
            await chipService.fetchLinks()
            // Schedule daily reminder
            notificationManager.scheduleDailyReminder()
        }
    }
}
