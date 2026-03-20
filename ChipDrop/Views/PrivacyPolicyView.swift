import SwiftUI

/// In-app Privacy Policy view
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        sectionTitle("Privacy Policy")

                        bodyText("Last updated: March 2026")

                        bodyText("ChipDrop (\"the App\") is a free utility that aggregates publicly available WSOP bonus links from freechipswsop.com. This Privacy Policy describes how we handle your information.")

                        sectionTitle("Information We Collect")

                        bodyText("The App does not collect, store, or transmit any personal information. We do not require account creation, login, or any form of registration.")

                        bulletPoint("No personal data is collected")
                        bulletPoint("No email addresses, names, or phone numbers")
                        bulletPoint("No location data")
                        bulletPoint("No financial or payment information")
                        bulletPoint("No tracking or analytics identifiers")
                    }

                    Group {
                        sectionTitle("Data Storage")

                        bodyText("All data is stored locally on your device only:")

                        bulletPoint("Cached chip links are stored in UserDefaults for offline access")
                        bulletPoint("Notification preferences are stored on-device")
                        bulletPoint("No data is transmitted to external servers other than fetching the public webpage")

                        sectionTitle("Third-Party Services")

                        bodyText("The App fetches publicly available data from freechipswsop.com. When you tap \"Collect\" on a chip link, it opens the link via your device's default browser or the WSOP app. We have no control over third-party sites or apps.")

                        sectionTitle("Push Notifications")

                        bodyText("If you enable push notifications, they are handled entirely through Apple's local notification system. No device token or push data is sent to any external server. Notifications are generated locally on your device when new chip links are detected.")
                    }

                    Group {
                        sectionTitle("Children's Privacy")

                        bodyText("The App is not directed to children under the age of 13. We do not knowingly collect any information from children.")

                        sectionTitle("Changes to This Policy")

                        bodyText("We may update this Privacy Policy from time to time. Changes will be reflected in the App with an updated revision date.")

                        sectionTitle("Contact")

                        bodyText("If you have questions about this Privacy Policy, please visit:")

                        Link("freechipswsop.com/contact", destination: URL(string: "https://freechipswsop.com/contact/")!)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.accent)

                        sectionTitle("Disclaimer")

                        bodyText("ChipDrop is an independent fan app. It is not affiliated with, endorsed by, or connected to Playtika Ltd., Caesars Entertainment, or the World Series of Poker (WSOP) brand. All trademarks belong to their respective owners.")
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(Theme.accent)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Privacy Policy")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(.top, 4)
    }

    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
