import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Tracks daily reading progress: pages visited, time spent, and streaks.
final class ReadingStatsManager: ObservableObject {
    static let shared = ReadingStatsManager()

    private let defaults = UserDefaults.standard
    private let pagesKey = "reading_stats_pages"
    private let streakKey = "reading_stats_streak"
    private let bestStreakKey = "reading_stats_best_streak"
    private let lastReadDateKey = "reading_stats_last_date"
    private let lifetimePagesKey = "reading_stats_lifetime_pages"
    private let lifetimeDaysKey = "reading_stats_lifetime_days"
    private let khatmCountKey = "reading_stats_khatm_count"
    private let dayOfWeekKey = "reading_stats_dow_counts"

    /// How many days of daily history to retain (used for heatmap).
    private let retentionDays = 90

    // MARK: - Published

    /// Pages read today
    @Published private(set) var todayPages: Set<Int> = []
    /// Current streak (consecutive days)
    @Published private(set) var currentStreak: Int = 0
    /// Best streak ever achieved
    @Published private(set) var bestStreak: Int = 0
    /// Distinct pages ever read (capped at 604)
    @Published private(set) var totalPagesRead: Int = 0
    /// Total distinct days the user has read at least one page
    @Published private(set) var lifetimeDaysRead: Int = 0
    /// Number of full mushaf completions (604 pages)
    @Published private(set) var khatmCount: Int = 0
    /// Pages read per weekday (1=Sunday ... 7=Saturday)
    @Published private(set) var dayOfWeekCounts: [Int: Int] = [:]

    // Session timer
    private var sessionStart: Date?

    private init() {
        loadTodayPages()
        bestStreak = defaults.integer(forKey: bestStreakKey)
        refreshStreak()
        let lifetime = Set(defaults.array(forKey: lifetimePagesKey) as? [Int] ?? [])
        totalPagesRead = lifetime.isEmpty ? loadAllTimePagesCount() : lifetime.count
        lifetimeDaysRead = defaults.integer(forKey: lifetimeDaysKey)
        khatmCount = defaults.integer(forKey: khatmCountKey)
        if let raw = defaults.dictionary(forKey: dayOfWeekKey) as? [String: Int] {
            var dict: [Int: Int] = [:]
            for (k, v) in raw { if let i = Int(k) { dict[i] = v } }
            dayOfWeekCounts = dict
        }
        persistForWidget()
    }

    // MARK: - Page Tracking

    /// Call this when the user navigates to a page.
    func recordPageView(_ page: Int) {
        let key = todayKey()

        // Load existing set for today
        var pages = loadPages(for: key)
        let wasEmpty = pages.isEmpty
        pages.insert(page)
        savePages(pages, for: key)

        todayPages = pages

        // Lifetime pages (capped at 604; increments khatm on rollover)
        var lifetime = Set(defaults.array(forKey: lifetimePagesKey) as? [Int] ?? [])
        lifetime.insert(page)
        if lifetime.count >= 604 {
            khatmCount += 1
            defaults.set(khatmCount, forKey: khatmCountKey)
            lifetime.removeAll()
        }
        defaults.set(Array(lifetime), forKey: lifetimePagesKey)
        totalPagesRead = lifetime.isEmpty ? loadAllTimePagesCount() : lifetime.count

        // If this is the first page today, update the streak + daily counters
        if wasEmpty {
            updateStreak()
            lifetimeDaysRead += 1
            defaults.set(lifetimeDaysRead, forKey: lifetimeDaysKey)
            let weekday = Calendar.current.component(.weekday, from: Date())
            dayOfWeekCounts[weekday, default: 0] += 1
            let raw = Dictionary(uniqueKeysWithValues: dayOfWeekCounts.map { (String($0.key), $0.value) })
            defaults.set(raw, forKey: dayOfWeekKey)
        }

        // Persist to shared container for widget
        persistForWidget()
    }

    /// Number of pages read on a specific date key (yyyy-MM-dd)
    func pagesRead(on dateKey: String) -> Int {
        loadPages(for: dateKey).count
    }

    /// Last 7 days of reading data: [(dayLabel, pagesCount)]
    func weeklyData() -> [(day: String, pages: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let dayLabels = DateFormatter()
        dayLabels.dateFormat = "EEE"

        var result: [(String, Int)] = []
        for offset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let key = formatter.string(from: date)
            let label = dayLabels.string(from: date)
            result.append((label, loadPages(for: key).count))
        }
        return result
    }

    /// Last `retentionDays` days (oldest → newest) with pages-read count per day.
    func heatmapData() -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var result: [(Date, Int)] = []
        for offset in (0..<retentionDays).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let key = formatter.string(from: date)
            result.append((date, loadPages(for: key).count))
        }
        return result
    }

    /// Most active weekday as a short name ("Mon", "Tue", ...) or nil if no data.
    var mostActiveWeekday: String? {
        guard let (weekday, _) = dayOfWeekCounts.max(by: { $0.value < $1.value }) else { return nil }
        let symbols = DateFormatter().shortWeekdaySymbols ?? ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        let idx = weekday - 1
        guard idx >= 0 && idx < symbols.count else { return nil }
        return symbols[idx]
    }

    // MARK: - Session Timer

    func startSession() {
        sessionStart = Date()
    }

    func endSession() {
        guard let start = sessionStart else { return }
        let elapsed = Date().timeIntervalSince(start)
        let key = "reading_session_\(todayKey())"
        let existing = defaults.double(forKey: key)
        defaults.set(existing + elapsed, forKey: key)
        sessionStart = nil
    }

    /// Total seconds read today
    var todayReadingTime: TimeInterval {
        let key = "reading_session_\(todayKey())"
        var total = defaults.double(forKey: key)
        // Add running session time
        if let start = sessionStart {
            total += Date().timeIntervalSince(start)
        }
        return total
    }

    /// Formatted reading time (e.g., "12 min" or "1h 23m")
    var todayReadingTimeFormatted: String {
        let seconds = Int(todayReadingTime)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "< 1 min"
        }
    }

    // MARK: - Reset

    func resetAll() {
        defaults.removeObject(forKey: pagesKey)
        defaults.removeObject(forKey: streakKey)
        defaults.removeObject(forKey: bestStreakKey)
        defaults.removeObject(forKey: lastReadDateKey)
        defaults.removeObject(forKey: lifetimePagesKey)
        defaults.removeObject(forKey: lifetimeDaysKey)
        defaults.removeObject(forKey: khatmCountKey)
        defaults.removeObject(forKey: dayOfWeekKey)

        // Clear session timers for the last 30 days
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for offset in 0..<30 {
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let key = "reading_session_\(formatter.string(from: date))"
            defaults.removeObject(forKey: key)
        }

        todayPages = []
        currentStreak = 0
        bestStreak = 0
        totalPagesRead = 0
        lifetimeDaysRead = 0
        khatmCount = 0
        dayOfWeekCounts = [:]
        sessionStart = nil

        persistForWidget()
    }

    // MARK: - Streak

    private func updateStreak() {
        let today = todayKey()
        let lastDate = defaults.string(forKey: lastReadDateKey) ?? ""

        if lastDate == today {
            // Already counted today
            return
        }

        let yesterday = dateKey(daysAgo: 1)
        if lastDate == yesterday {
            // Consecutive day
            currentStreak += 1
        } else if lastDate != today {
            // Streak broken (or first day)
            currentStreak = 1
        }

        // Update best streak
        if currentStreak > bestStreak {
            bestStreak = currentStreak
            defaults.set(bestStreak, forKey: bestStreakKey)
        }

        defaults.set(currentStreak, forKey: streakKey)
        defaults.set(today, forKey: lastReadDateKey)
    }

    private func refreshStreak() {
        currentStreak = defaults.integer(forKey: streakKey)
        let lastDate = defaults.string(forKey: lastReadDateKey) ?? ""
        let today = todayKey()
        let yesterday = dateKey(daysAgo: 1)

        // If last read was before yesterday, streak is broken
        if lastDate != today && lastDate != yesterday {
            currentStreak = 0
            defaults.set(0, forKey: streakKey)
        }
    }

    // MARK: - Persistence

    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func dateKey(daysAgo: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return formatter.string(from: date)
    }

    private func loadPages(for dateKey: String) -> Set<Int> {
        let dict = defaults.dictionary(forKey: pagesKey) as? [String: [Int]] ?? [:]
        return Set(dict[dateKey] ?? [])
    }

    private func savePages(_ pages: Set<Int>, for dateKey: String) {
        var dict = defaults.dictionary(forKey: pagesKey) as? [String: [Int]] ?? [:]
        dict[dateKey] = Array(pages)

        // Prune entries older than 30 days
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        let cutoffKey = formatter.string(from: cutoff)
        dict = dict.filter { $0.key >= cutoffKey }

        defaults.set(dict, forKey: pagesKey)
    }

    private func loadTodayPages() {
        todayPages = loadPages(for: todayKey())
    }

    private func loadAllTimePagesCount() -> Int {
        let dict = defaults.dictionary(forKey: pagesKey) as? [String: [Int]] ?? [:]
        var allPages = Set<Int>()
        for (_, pages) in dict {
            allPages.formUnion(pages)
        }
        return allPages.count
    }

    // MARK: - Widget Persistence

    /// Completion percentage (0-100)
    var completionPercentage: Double {
        Double(totalPagesRead) / 604.0 * 100.0
    }

    private func persistForWidget() {
        guard let defaults = UserDefaults(suiteName: "group.com.mehdi.furqan") else { return }
        defaults.set(todayPages.count, forKey: "widget_today_pages")
        defaults.set(currentStreak, forKey: "widget_streak")
        defaults.set(totalPagesRead, forKey: "widget_total_pages")
        defaults.set(completionPercentage, forKey: "widget_completion")
        defaults.synchronize()
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "ReadingProgressWidget")
        #endif
    }
}
