import SwiftUI

/// Slide-out side menu — Midnight Emerald theme
struct SideMenuView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var chipService: ChipService

    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) { isShowing = false }
                }

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Image(systemName: "suit.club.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.accent)
                        Text("ChipDrop")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text("Free WSOP Chips Daily")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)

                    Divider()
                        .background(Theme.surfaceLight)
                        .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)

                // Stats cards
                VStack(spacing: 10) {
                    statRow(icon: "link.circle.fill", title: "Total Links", value: "\(chipService.allLinks.count)", color: Theme.accentAlt)
                    statRow(icon: "clock.fill", title: "Today", value: "\(chipService.todayLinks.count)", color: Theme.accent)
                    statRow(icon: "flame.fill", title: "Chips Today", value: formatNumber(chipService.totalChipsToday), color: Theme.gold)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                Divider()
                    .background(Theme.surfaceLight)
                    .padding(.horizontal, 20)

                // Menu items
                VStack(spacing: 2) {
                    menuItem(icon: "house.fill", title: "Home", color: Theme.accent) { isShowing = false }
                    menuItem(icon: "gift.fill", title: "Rewards", color: Theme.gold) { isShowing = false }
                    menuItem(icon: "bell.fill", title: "Notifications", color: Theme.accentAlt) {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        isShowing = false
                    }

                }
                .padding(.top, 12)

                Spacer()

                Text("Version 1.0")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
            .frame(width: 280)
            .background(Theme.bg.ignoresSafeArea())
        }
    }

    private func statRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 22)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
    }

    private func menuItem(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(color)
                    .frame(width: 22)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

#Preview {
    SideMenuView(isShowing: .constant(true))
        .environmentObject(ChipService.shared)
}
