import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

/// Service responsible for scraping chip links from freechipswsop.com
/// Listens to Firestore in real-time so the app updates the moment the Cloud
/// Function detects new chips — no manual refresh needed.
class ChipService: ObservableObject {
    @Published var allLinks: [ChipLink] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?

    private let baseURL = "https://freechipswsop.com"
    private let cacheKey = "cached_chip_links"
    private let lastFetchKey = "last_fetch_date"
    private let sharedCacheDocument = "cached_links"

    private var refreshTimer: AnyCancellable?
    private let autoRefreshInterval: TimeInterval = 600 // 10 minutes fallback

    /// Live Firestore listener — fires whenever the Cloud Function writes new chips
    private var firestoreListener: ListenerRegistration?

    /// Tracks the last Firestore timestamp we saw — kept separate from
    /// `lastUpdated` so that the comparison is always apples-to-apples
    /// (server timestamp vs. server timestamp, never vs. local Date()).
    private var lastSeenFirestoreTimestamp: Date?

    static let shared = ChipService()

    init() {
        loadCachedLinks()
        startAutoRefresh()
    }

    // MARK: - Firestore Real-Time Listener

    /// Watches the Cloud Function's `chip_data/seen_urls` document.
    /// When the shared cached links document changes, we update local state.
    func startFirestoreListener() {
        guard firestoreListener == nil else { return }

        let db = Firestore.firestore()
        firestoreListener = db.collection("chip_data").document(sharedCacheDocument)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let data = snapshot?.data() else {
                    if let error {
                        print("❌ Firestore cache listener error: \(error.localizedDescription)")
                    }
                    return
                }

                Task { @MainActor in
                    self.applySharedCachePayload(data)
                }
            }
    }

    func stopFirestoreListener() {
        firestoreListener?.remove()
        firestoreListener = nil
    }

    // MARK: - Auto Refresh (fallback timer)

    func startAutoRefresh() {
        refreshTimer?.cancel()
        refreshTimer = Timer.publish(every: autoRefreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.fetchLinks()
                }
            }
    }

    func stopAutoRefresh() {
        refreshTimer?.cancel()
        refreshTimer = nil
    }

    // MARK: - Fetch

    @MainActor
    func fetchLinks() async {
        isLoading = true
        errorMessage = nil

        if await loadSharedCache() {
            isLoading = false
            return
        }

        do {
            guard let url = URL(string: baseURL) else {
                errorMessage = "Invalid URL"
                isLoading = false
                return
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "Server error. Please try again."
                isLoading = false
                return
            }

            guard let html = String(data: data, encoding: .utf8) else {
                errorMessage = "Failed to decode response"
                isLoading = false
                return
            }

            let previousURLs = Set(allLinks.map { $0.url })
            let parsedLinks = parseHTML(html)

            guard !parsedLinks.isEmpty else {
                errorMessage = "Couldn't load shared cache or parse live chip links. Please try again."
                isLoading = false
                return
            }

            let newURLs = Set(parsedLinks.map { $0.url })
            let brandNewURLs = newURLs.subtracting(previousURLs)

            if !brandNewURLs.isEmpty && !previousURLs.isEmpty {
                let newCount = brandNewURLs.count
                await NotificationManager.shared.sendNewChipsNotification(count: newCount)
            }

            allLinks = parsedLinks
            lastUpdated = Date()
            cacheLinks()
            isLoading = false

        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func loadSharedCache() async -> Bool {
        await withCheckedContinuation { continuation in
            Firestore.firestore().collection("chip_data").document(sharedCacheDocument)
                .getDocument { [weak self] snapshot, error in
                    guard let self = self,
                          error == nil,
                          let data = snapshot?.data() else {
                        continuation.resume(returning: false)
                        return
                    }

                    Task { @MainActor in
                        let didApply = self.applySharedCachePayload(data)
                        continuation.resume(returning: didApply)
                    }
                }
        }
    }

    @MainActor
    @discardableResult
    private func applySharedCachePayload(_ data: [String: Any]) -> Bool {
        guard let rawLinks = data["links"] as? [[String: Any]], !rawLinks.isEmpty else {
            return false
        }

        let collectedURLs = Set(allLinks.filter { $0.isCollected }.map { $0.url })
        let decodedLinks = rawLinks.compactMap(decodeSharedLink(from:))

        guard !decodedLinks.isEmpty else { return false }

        allLinks = decodedLinks.map { link in
            var link = link
            link.isCollected = collectedURLs.contains(link.url)
            return link
        }

        if let fetched = data["lastFetchedAt"] as? Timestamp {
            lastUpdated = fetched.dateValue()
        } else if let updated = data["contentUpdatedAt"] as? Timestamp {
            lastUpdated = updated.dateValue()
        }

        if let contentUpdated = data["contentUpdatedAt"] as? Timestamp {
            let serverDate = contentUpdated.dateValue()
            if let lastSeen = lastSeenFirestoreTimestamp {
                if serverDate > lastSeen {
                    print("🔔 Firestore cache updated — applying shared links")
                }
            }
            lastSeenFirestoreTimestamp = serverDate
        }

        cacheLinks()
        errorMessage = nil
        return true
    }

    private func decodeSharedLink(from raw: [String: Any]) -> ChipLink? {
        guard let title = raw["title"] as? String,
              let url = raw["url"] as? String,
              let dateString = raw["dateString"] as? String,
              let dateTimestamp = raw["datePosted"] as? Timestamp,
              let rewardTypeRaw = raw["rewardType"] as? String,
              let rewardType = ChipLink.RewardType(rawValue: rewardTypeRaw) else {
            return nil
        }

        return ChipLink(
            id: UUID(),
            title: title,
            url: url,
            dateString: dateString,
            datePosted: dateTimestamp.dateValue(),
            chipAmount: raw["chipAmount"] as? Int ?? 0,
            rewardType: rewardType,
            isNew: raw["isNew"] as? Bool ?? false,
            isCollected: false
        )
    }

    // MARK: - Parse

    private func parseHTML(_ html: String) -> [ChipLink] {
        var links: [ChipLink] = []
        var currentDateString = ""
        var currentDate: Date? = nil  // nil until we see a valid h3

        let lines = html.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let dateMatch = extractDateFromH3(trimmed) {
                currentDateString = dateMatch.0
                currentDate = dateMatch.1
                continue
            }

            // Only extract links once we have a valid date context
            guard let date = currentDate else { continue }

            let extractedLinks = extractLinksFromLine(trimmed, dateString: currentDateString, date: date)
            links.append(contentsOf: extractedLinks)
        }

        var seenURLs = Set<String>()
        let uniqueLinks = links.filter { link in
            if seenURLs.contains(link.url) { return false }
            seenURLs.insert(link.url)
            return true
        }

        return uniqueLinks.sorted { $0.datePosted > $1.datePosted }
    }

    private func extractDateFromH3(_ line: String) -> (String, Date)? {
        guard line.contains("<h3") && line.contains("</h3>") else { return nil }

        // Strip any attributes from h3 tag
        var cleaned = line
        if let range = cleaned.range(of: "<h3[^>]*>", options: .regularExpression) {
            cleaned = String(cleaned[range.upperBound...])
        } else {
            cleaned = cleaned.replacingOccurrences(of: "<h3>", with: "")
        }
        cleaned = cleaned.replacingOccurrences(of: "</h3>", with: "")
                         .trimmingCharacters(in: .whitespaces)

        // Remove any remaining HTML tags
        cleaned = cleaned.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                         .trimmingCharacters(in: .whitespaces)

        guard !cleaned.isEmpty else { return nil }

        let displayString = cleaned

        // Remove ordinal suffixes (st, nd, rd, th)
        let dateStr = cleaned
            .replacingOccurrences(of: "([0-9]+)(st|nd|rd|th)", with: "$1", options: .regularExpression)
            .replacingOccurrences(of: "Feburary", with: "February")
            .trimmingCharacters(in: .whitespaces)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let formats = ["d MMMM yyyy", "MMMM d, yyyy", "MMMM d yyyy", "d MMMM, yyyy"]
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateStr) {
                return (displayString, date)
            }
        }

        return nil
    }

    private func extractLinksFromLine(_ line: String, dateString: String, date: Date) -> [ChipLink] {
        var links: [ChipLink] = []

        let pattern = #"<a[^>]*href="(https://www\.wsopga\.me/[^"]+)"[^>]*>([^<]+)</a>"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return links
        }

        let range = NSRange(line.startIndex..., in: line)
        let matches = regex.matches(in: line, options: [], range: range)

        for match in matches {
            guard match.numberOfRanges >= 3,
                  let urlRange = Range(match.range(at: 1), in: line),
                  let titleRange = Range(match.range(at: 2), in: line) else { continue }

            let url = String(line[urlRange])
            let title = String(line[titleRange]).trimmingCharacters(in: .whitespaces)

            let chipLink = ChipLink.parse(from: title, url: url, dateString: dateString, date: date)
            links.append(chipLink)
        }

        return links
    }

    // MARK: - Caching

    private func cacheLinks() {
        if let encoded = try? JSONEncoder().encode(allLinks) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: lastFetchKey)
        }
    }

    private func loadCachedLinks() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let links = try? JSONDecoder().decode([ChipLink].self, from: data) {
            allLinks = links
            lastUpdated = UserDefaults.standard.object(forKey: lastFetchKey) as? Date
        }
    }

    // MARK: - Filtered / Grouped Data

    /// Links grouped by date, sorted newest first
    var groupedByDate: [DailyChipLinks] {
        let grouped = Dictionary(grouping: allLinks) { $0.dateString }
        return grouped.map { key, value in
            DailyChipLinks(dateString: key, date: value.first?.datePosted ?? Date(), links: value)
        }.sorted { $0.date > $1.date }
    }

    /// The latest day's group (the "today" section on the site)
    var latestDayGroup: DailyChipLinks? {
        groupedByDate.first
    }

    /// Links from the latest day only
    var todayLinks: [ChipLink] {
        latestDayGroup?.links ?? []
    }

    /// All links except the latest day
    var olderGroups: [DailyChipLinks] {
        Array(groupedByDate.dropFirst())
    }

    /// Total chips from the latest day
    var totalChipsToday: Int {
        todayLinks.reduce(0) { $0 + $1.chipAmount }
    }

    /// Total chips across ALL links
    var totalChips: Int {
        allLinks.reduce(0) { $0 + $1.chipAmount }
    }

    func markCollected(_ link: ChipLink) {
        if let index = allLinks.firstIndex(where: { $0.id == link.id }) {
            allLinks[index].isCollected = true
            cacheLinks()
        }
    }
}
