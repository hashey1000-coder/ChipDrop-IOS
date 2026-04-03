import Foundation

/// Represents a single chip reward link scraped from freechipswsop.com
struct ChipLink: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String        // e.g. "450,000+ Free Chips" or "Free WSOP Coffee Mug"
    let url: String          // The wsopga.me claim URL
    let dateString: String   // e.g. "20th March 2026"
    let datePosted: Date     // Parsed date for sorting
    let chipAmount: Int      // Parsed chip count (0 for non-chip rewards)
    let rewardType: RewardType
    var isNew: Bool          // Whether this link is from today/recent
    var isCollected: Bool    // User has tapped collect

    enum RewardType: String, Codable {
        case chips
        case freeSpins
        case coffeeMug
        case ribbons
        case other
    }

    /// Formatted chip amount string like "450,000"
    var formattedAmount: String {
        if chipAmount > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: chipAmount)) ?? "\(chipAmount)"
        }
        return title
    }

    /// Display title for the reward card
    var displayTitle: String {
        switch rewardType {
        case .chips:
            return "\(formattedAmount) Chips!"
        case .freeSpins:
            return "Free Spins Bonus!"
        case .coffeeMug:
            return "Free Coffee Mug!"
        case .ribbons:
            return "120 Ribbons!"
        case .other:
            return title
        }
    }

    /// Time ago string — shows hours for today, then days/weeks for older links.
    /// Time ago string — the website only provides dates (no timestamps),
    /// so we show "Today" / "Yesterday" for recent, then day/week counts for older.
    var timeAgo: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(datePosted) {
            return "Today"
        }
        if calendar.isDateInYesterday(datePosted) {
            return "Yesterday"
        }

        let components = calendar.dateComponents([.day], from: datePosted, to: Date())
        let days = components.day ?? 0

        if days < 7 {
            return "\(days) days ago"
        }
        if days < 14 {
            return "1 week ago"
        }

        let weeks = days / 7
        return "\(weeks) weeks ago"
    }

    /// Icon name for the reward type
    var iconName: String {
        switch rewardType {
        case .chips: return "chip_icon"
        case .freeSpins: return "star.circle.fill"
        case .coffeeMug: return "cup.and.saucer.fill"
        case .ribbons: return "gift.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    static func parse(from title: String, url: String, dateString: String, date: Date) -> ChipLink {
        var rewardType: RewardType = .other
        var chipAmount = 0

        if title.lowercased().contains("free chips") {
            rewardType = .chips
            // Extract number from title
            let numbers = title.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .joined()
            chipAmount = Int(numbers) ?? 450000
            if chipAmount < 1000 {
                chipAmount = 450000 // Default WSOP chip amount
            }
        } else if title.lowercased().contains("free spins") {
            rewardType = .freeSpins
        } else if title.lowercased().contains("coffee mug") {
            rewardType = .coffeeMug
        } else if title.lowercased().contains("ribbon") {
            rewardType = .ribbons
        }

        let calendar = Calendar.current
        let isNew = calendar.isDateInToday(date) || calendar.isDateInYesterday(date)

        return ChipLink(
            id: UUID(),
            title: title,
            url: url,
            dateString: dateString,
            datePosted: date,
            chipAmount: chipAmount,
            rewardType: rewardType,
            isNew: isNew,
            isCollected: false
        )
    }
}

/// Groups links by date
struct DailyChipLinks: Identifiable {
    let id = UUID()
    let dateString: String
    let date: Date
    let links: [ChipLink]
}
