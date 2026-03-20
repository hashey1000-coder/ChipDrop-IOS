import SwiftUI

/// Home screen — Midnight Emerald theme
struct HomeView: View {
    @EnvironmentObject var chipService: ChipService
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showSideMenu = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    collectBanner
                        .padding(.top, 16)

                    statsStrip

                    gridButtons

                    privacyPolicyLink

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }

            if showSideMenu {
                SideMenuView(isShowing: $showSideMenu)
                    .transition(.move(edge: .leading))
                    .zIndex(10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showSideMenu.toggle()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: "suit.club.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                    Text("ChipDrop")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Collect Banner

    private var collectBanner: some View {
        NavigationLink(destination: RewardsListView()) {
            HStack(spacing: 12) {
                ChipIconView(size: 65, style: .dual)
                    .padding(.leading, 12)

                Spacer()

                VStack(spacing: 4) {
                    Text("Collect Now!")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    if chipService.todayLinks.count > 0 {
                        Text("\(chipService.todayLinks.count) links today")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.trailing, 16)
            }
            .frame(height: 100)
            .background(
                Theme.chipCardGradient
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            )
            .glowRing(cornerRadius: 22)
            .shadow(color: Theme.accent.opacity(0.25), radius: 18, y: 6)
        }
    }

    // MARK: - Stats Strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statPill(value: "\(chipService.todayLinks.count)", label: "Today", color: Theme.accent)
            
            Rectangle()
                .fill(Theme.surfaceLight)
                .frame(width: 1, height: 30)
            
            statPill(value: "\(chipService.allLinks.count)", label: "Total", color: Theme.accentAlt)
            
            Rectangle()
                .fill(Theme.surfaceLight)
                .frame(width: 1, height: 30)
            
            statPill(value: compactNumber(chipService.totalChipsToday), label: "Chips Today", color: Theme.gold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
        )
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Grid Buttons

    private var gridButtons: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                NavigationLink(destination: GuideView()) {
                    menuTile(icon: "book.fill", title: "Guide", color: Theme.accent)
                }

                Button {
                    Task { await chipService.fetchLinks() }
                } label: {
                    menuTile(
                        icon: chipService.isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise.circle.fill",
                        title: chipService.isLoading ? "Loading..." : "Refresh",
                        color: Theme.accentAlt
                    )
                }
                .disabled(chipService.isLoading)
            }

            HStack(spacing: 14) {
                Button { shareApp() } label: {
                    menuTile(icon: "square.and.arrow.up.fill", title: "Share", color: Theme.gold)
                }

                Button { rateApp() } label: {
                    menuTile(icon: "star.fill", title: "Rate", color: Color(red: 1.0, green: 0.55, blue: 0.2))
                }
            }
        }
    }

    private func menuTile(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
        )
    }

    // MARK: - Privacy Policy (in-app)

    private var privacyPolicyLink: some View {
        NavigationLink(destination: PrivacyPolicyView()) {
            HStack(spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.accentAlt)

                Text("Privacy Policy")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface)
            )
        }
    }

    // MARK: - Helpers

    /// Compact number: 1.2K, 3.5M, 1.1B etc.
    private func compactNumber(_ value: Int) -> String {
        let d = Double(value)
        switch d {
        case 1_000_000_000...:
            let v = d / 1_000_000_000
            return v.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0fB", v)
                : String(format: "%.1fB", v)
        case 1_000_000...:
            let v = d / 1_000_000
            return v.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0fM", v)
                : String(format: "%.1fM", v)
        case 1_000...:
            let v = d / 1_000
            return v.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0fK", v)
                : String(format: "%.1fK", v)
        default:
            return "\(value)"
        }
    }

    private func shareApp() {
        let text = "🎰 Check out ChipDrop! Get free WSOP chips daily!\nhttps://freechipswsop.com"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/id0000000000") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(ChipService.shared)
            .environmentObject(NotificationManager.shared)
    }
}
