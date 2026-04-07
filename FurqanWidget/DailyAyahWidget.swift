import WidgetKit
import SwiftUI
import SQLite3

// MARK: - Daily Ayah Data

struct DailyAyahEntry: TimelineEntry {
    let date: Date
    let surah: Int
    let ayah: Int
    let surahName: String
    let translationText: String
    let reference: String
}

// MARK: - Provider

struct DailyAyahProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyAyahEntry {
        DailyAyahEntry(
            date: Date(),
            surah: 1,
            ayah: 1,
            surahName: "Al-Fatihah",
            translationText: "In the Name of Allah, the Most Gracious, the Most Merciful.",
            reference: "1:1"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyAyahEntry) -> Void) {
        completion(fetchDailyAyah())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyAyahEntry>) -> Void) {
        let entry = fetchDailyAyah()

        // Refresh at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())

        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    /// Pick a deterministic ayah based on the day of the year so it changes daily.
    private func fetchDailyAyah() -> DailyAyahEntry {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1

        // Curated popular ayahs for daily rotation
        let curated: [(surah: Int, ayah: Int)] = [
            (1, 1), (1, 2), (1, 5), (1, 6),
            (2, 152), (2, 155), (2, 156), (2, 186), (2, 216), (2, 255), (2, 257), (2, 268), (2, 286),
            (3, 8), (3, 26), (3, 139), (3, 159), (3, 173), (3, 185), (3, 200),
            (4, 29), (4, 79),
            (5, 2), (5, 32),
            (6, 17), (6, 59), (6, 162),
            (7, 56), (7, 126), (7, 156),
            (8, 46),
            (9, 40), (9, 51), (9, 105), (9, 128), (9, 129),
            (10, 57), (10, 62),
            (11, 6), (11, 56), (11, 88),
            (12, 21), (12, 64), (12, 86), (12, 87),
            (13, 11), (13, 28),
            (14, 7), (14, 40), (14, 41),
            (15, 56),
            (16, 18), (16, 53), (16, 90), (16, 97), (16, 128),
            (17, 23), (17, 24), (17, 44), (17, 80), (17, 82),
            (18, 10), (18, 39), (18, 46),
            (19, 65),
            (20, 14), (20, 25), (20, 46),
            (21, 35), (21, 83), (21, 87),
            (23, 116), (23, 118),
            (24, 35),
            (25, 74),
            (27, 62),
            (28, 24),
            (29, 45), (29, 69),
            (30, 21),
            (31, 17), (31, 18),
            (33, 41), (33, 43), (33, 56),
            (35, 2), (35, 34),
            (36, 58), (36, 82),
            (38, 35),
            (39, 10), (39, 53),
            (40, 44), (40, 60),
            (41, 30), (41, 34),
            (42, 19),
            (47, 7),
            (48, 29),
            (49, 13),
            (50, 16),
            (51, 56),
            (52, 48),
            (53, 39),
            (55, 13),
            (56, 10),
            (57, 4),
            (59, 22), (59, 23), (59, 24),
            (62, 10),
            (64, 11),
            (65, 2), (65, 3),
            (67, 1), (67, 2),
            (68, 4),
            (73, 8), (73, 20),
            (76, 9),
            (78, 40),
            (87, 1),
            (89, 27), (89, 28), (89, 29), (89, 30),
            (93, 5), (93, 7), (93, 8),
            (94, 5), (94, 6),
            (95, 4),
            (96, 1),
            (112, 1), (112, 2), (112, 3), (112, 4),
            (113, 1),
            (114, 1),
        ]

        let index = (dayOfYear - 1) % curated.count
        let ayahRef = curated[index]

        // Load translation from the bundled DB
        let translation = loadTranslation(surah: ayahRef.surah, ayah: ayahRef.ayah)
        let surahName = loadSurahName(surah: ayahRef.surah)

        return DailyAyahEntry(
            date: Date(),
            surah: ayahRef.surah,
            ayah: ayahRef.ayah,
            surahName: surahName,
            translationText: translation,
            reference: "\(ayahRef.surah):\(ayahRef.ayah)"
        )
    }

    private func loadTranslation(surah: Int, ayah: Int) -> String {
        guard let path = Bundle.main.path(forResource: "translation-en", ofType: "db") else {
            return "All praise is due to Allah, Lord of the worlds."
        }
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return "All praise is due to Allah, Lord of the worlds."
        }
        defer { if let db { sqlite3_close(db) } }

        let query = "SELECT text FROM verses WHERE sura = ? AND ayah = ? LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
            return "All praise is due to Allah, Lord of the worlds."
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(surah))
        sqlite3_bind_int(stmt, 2, Int32(ayah))

        if sqlite3_step(stmt) == SQLITE_ROW, let text = sqlite3_column_text(stmt, 0) {
            var result = String(cString: text)
            // Clean up footnotes
            result = result.replacingOccurrences(of: "\\[\\[.*?\\]\\]", with: "", options: .regularExpression)
            result = result.replacingOccurrences(of: "<sup.*?</sup>", with: "", options: .regularExpression)
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "All praise is due to Allah, Lord of the worlds."
    }

    private func loadSurahName(surah: Int) -> String {
        guard let path = Bundle.main.path(forResource: "surahMetadata", ofType: "db") else {
            return "Al-Fatihah"
        }
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return "Al-Fatihah"
        }
        defer { if let db { sqlite3_close(db) } }

        let query = "SELECT name_simple FROM chapters WHERE id = ? LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
            return "Al-Fatihah"
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(surah))
        if sqlite3_step(stmt) == SQLITE_ROW, let text = sqlite3_column_text(stmt, 0) {
            return String(cString: text)
        }
        return "Al-Fatihah"
    }
}

// MARK: - Widget Views

struct DailyAyahWidgetEntryView: View {
    var entry: DailyAyahEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Daily Ayah")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(entry.translationText)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .lineLimit(5)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Text("\(entry.surahName) \(entry.reference)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.green)
        }
        .padding(14)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Daily Ayah")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.surahName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }

            Text(entry.translationText)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .lineLimit(4)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)

            HStack {
                Text("Surah \(entry.surahName), Ayah \(entry.ayah)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("FURQAN.")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
    }
}

// MARK: - Widget Definition

struct DailyAyahWidget: Widget {
    let kind: String = "DailyAyahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyAyahProvider()) { entry in
            if #available(iOS 17.0, *) {
                DailyAyahWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DailyAyahWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Daily Ayah")
        .description("A new ayah every day to reflect upon.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
