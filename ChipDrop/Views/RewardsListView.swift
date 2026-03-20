import SwiftUI

/// Rewards list — today's links shown, older days in collapsible dropdowns
struct RewardsListView: View {
    @EnvironmentObject var chipService: ChipService
    @Environment(\.dismiss) var dismiss
    @State private var selectedLink: ChipLink?
    @State private var expandedDays: Set<String> = []

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if chipService.isLoading && chipService.allLinks.isEmpty {
                loadingView
            } else if chipService.allLinks.isEmpty {
                emptyView
            } else {
                linksList
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
                Text("Rewards")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.accent)
            }
        }
        .sheet(item: $selectedLink) { link in
            CollectRewardView(chipLink: link)
                .environmentObject(chipService)
        }
        .refreshable {
            await chipService.fetchLinks()
        }
    }

    // MARK: - Links List

    private var linksList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Status bar
                if let lastUpdated = chipService.lastUpdated {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Theme.textMuted)
                        Text("Updated \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Text("\(chipService.todayLinks.count) today · \(chipService.allLinks.count) total")
                            .font(.caption.bold())
                            .foregroundColor(Theme.accent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }

                // ── Today's section (always expanded) ──
                if let todayGroup = chipService.latestDayGroup {
                    todaySectionHeader(todayGroup)

                    ForEach(todayGroup.links) { link in
                        RewardRowView(link: link) {
                            selectedLink = link
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    }
                }

                // ── Older days (collapsible dropdowns) ──
                if !chipService.olderGroups.isEmpty {
                    Text("Previous Days")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 4)

                    ForEach(chipService.olderGroups) { group in
                        olderDaySection(group)
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Today Section Header

    private func todaySectionHeader(_ group: DailyChipLinks) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill")
                .foregroundColor(Theme.gold)
                .font(.system(size: 14, weight: .semibold))

            Text(group.dateString)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            PillTag(text: "LATEST", color: Theme.accent)

            Rectangle()
                .fill(Theme.surfaceLight)
                .frame(height: 1)

            Text("\(group.links.count)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.accent.opacity(0.15)))
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Older Day Section (Collapsible)

    private func olderDaySection(_ group: DailyChipLinks) -> some View {
        VStack(spacing: 0) {
            // Dropdown header
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if expandedDays.contains(group.dateString) {
                        expandedDays.remove(group.dateString)
                    } else {
                        expandedDays.insert(group.dateString)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .foregroundColor(Theme.accentAlt)
                        .font(.system(size: 14, weight: .semibold))

                    Text(group.dateString)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(group.links.count) links")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textSecondary)

                    Image(systemName: expandedDays.contains(group.dateString) ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.surface)
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            // Expanded links
            if expandedDays.contains(group.dateString) {
                ForEach(group.links) { link in
                    RewardRowView(link: link) {
                        selectedLink = link
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.accent)

            Text("Loading chip links...")
                .font(.headline)
                .foregroundColor(Theme.textSecondary)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.textMuted)

            Text("No chip links available")
                .font(.title3.bold())
                .foregroundColor(.white)

            Text("Pull down to refresh or tap Refresh on the home screen")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await chipService.fetchLinks() }
            } label: {
                Text("Retry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Theme.collectGradient)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
}

// MARK: - Reward Row View

struct RewardRowView: View {
    let link: ChipLink
    let onCollect: () -> Void

    var body: some View {
        Button(action: onCollect) {
            HStack(spacing: 12) {
                ZStack(alignment: .topLeading) {
                    Group {
                        if link.rewardType == .chips {
                            ChipIconView(size: 46, style: .dual)
                        } else {
                            BingoBallsView(size: 46)
                        }
                    }

                    if link.isNew {
                        PillTag(text: "NEW", color: Theme.danger)
                            .offset(x: -10, y: -6)
                    }
                }
                .frame(width: 56)

                VStack(alignment: .leading, spacing: 3) {
                    Text(link.displayTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(link.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Text(link.isCollected ? "Done" : "Collect")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        link.isCollected
                            ? AnyShapeStyle(Theme.surfaceLight)
                            : AnyShapeStyle(Theme.collectGradient)
                    )
                    .clipShape(Capsule())
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(link.isCollected)
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        RewardsListView()
            .environmentObject(ChipService.shared)
    }
}
