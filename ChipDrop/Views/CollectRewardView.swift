import SwiftUI

/// Collect Reward detail — Midnight Emerald theme
struct CollectRewardView: View {
    let chipLink: ChipLink
    @EnvironmentObject var chipService: ChipService
    @Environment(\.dismiss) var dismiss
    @State private var isCollecting = false
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Theme.surface))
                    }
                    Spacer()
                    Text("Collect Reward")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    // Balance spacer
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Reward card
                rewardCard
                    .padding(.horizontal, 20)

                // Action buttons
                actionButtons
                    .padding(.horizontal, 20)

                // Disclaimer
                Text("Links have a time limit. If collection fails, the link may have expired. Try again with new links!")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 4)

                Spacer()
            }

            if showSuccess { successOverlay }
        }
    }

    // MARK: - Reward Card

    private var rewardCard: some View {
        VStack(spacing: 16) {
            ChipIconView(size: 110, style: .dual)
                .padding(.top, 28)

            Text(chipLink.displayTitle)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

            if chipLink.chipAmount > 0 {
                PillTag(text: "\(chipLink.chipAmount / 1000)K Chips", color: Theme.gold)
            }

            Spacer().frame(height: 10)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Theme.chipCardGradient)
        )
        .glowRing(cornerRadius: 24)
        .shadow(color: Theme.accent.opacity(0.2), radius: 20, y: 10)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 14) {
            Button { shareReward() } label: {
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.accentAlt)
                    Text("Share")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
            }

            Button { collectReward() } label: {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                    Text("Collect!")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.collectGradient))
            }
            .disabled(isCollecting)
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(Theme.accent)

                Text("Opening WSOP...")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Collect your chips in the app!")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Theme.surface)
            )
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private func collectReward() {
        isCollecting = true
        withAnimation(.spring()) { showSuccess = true }
        chipService.markCollected(chipLink)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let url = URL(string: chipLink.url) {
                UIApplication.shared.open(url)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { showSuccess = false; isCollecting = false }
                dismiss()
            }
        }
    }

    private func shareReward() {
        let text = "🎰 I just collected \(chipLink.displayTitle) from ChipDrop! Download the app to collect your free chips daily."
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    CollectRewardView(
        chipLink: ChipLink(
            id: UUID(), title: "Claim 450,000+ Free Chips",
            url: "https://www.wsopga.me/test", dateString: "20th March 2026",
            datePosted: Date(), chipAmount: 450000, rewardType: .chips,
            isNew: true, isCollected: false
        )
    )
    .environmentObject(ChipService.shared)
}
