import SwiftUI

/// Guide screen — Midnight Emerald theme
struct GuideView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Collect Free Chips")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.heroGradient)
                        .padding(.top, 10)

                    stepCard(number: 1, title: "Open WSOP App", description: "Open the WSOP app on your device and keep it running in the background.", icon: "iphone", color: Theme.accent)

                    stepCard(number: 2, title: "Tap Collect", description: "Browse the Rewards page and tap 'Collect' on any available chip link.", icon: "hand.tap.fill", color: Theme.accentAlt)

                    stepCard(number: 3, title: "Open in WSOP", description: "When prompted, tap 'Open' to redirect to the WSOP app. Wait a moment for chips to load.", icon: "arrow.up.forward.app.fill", color: Theme.gold)

                    stepCard(number: 4, title: "Enjoy Your Chips!", description: "Tap 'Collect' in the WSOP app to receive your free chips. Repeat for all links!", icon: "gift.fill", color: Theme.accent)

                    // Tips
                    VStack(alignment: .leading, spacing: 10) {
                        Text("💡 Tips")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        tipRow("Each link can only be used once")
                        tipRow("Links expire after a limited time")
                        tipRow("Check back daily for new chip drops")
                        tipRow("Enable notifications to never miss chips")
                        tipRow("Connect Facebook to save progress")
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Guide")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }

    private func stepCard(number: Int, title: String, description: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 42, height: 42)
                Text("\(number)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.accent)
                .font(.system(size: 13))
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    NavigationStack { GuideView() }
}
