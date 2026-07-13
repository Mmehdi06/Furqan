import Foundation

// MARK: - Line & Page Models

enum LineType: String {
    case ayah
    case basmallah
    case surahName = "surah_name"
}

struct QuranWord: Identifiable {
    let id: Int
    let location: String
    let surah: Int
    let ayah: Int
    let wordPosition: Int
    let text: String
}

struct QuranLine: Identifiable {
    let id: String
    let lineNumber: Int
    let lineType: LineType
    let isCentered: Bool
    let surahNumber: Int?
    let words: [QuranWord]

    /// Unique ayahs present on this line (pre-computed at init)
    let ayahsOnLine: [(surah: Int, ayah: Int)]

    init(id: String, lineNumber: Int, lineType: LineType, isCentered: Bool, surahNumber: Int?, words: [QuranWord]) {
        self.id = id
        self.lineNumber = lineNumber
        self.lineType = lineType
        self.isCentered = isCentered
        self.surahNumber = surahNumber
        self.words = words

        // Pre-compute unique ayahs
        var seen = Set<String>()
        var result: [(surah: Int, ayah: Int)] = []
        for word in words {
            let key = "\(word.surah):\(word.ayah)"
            if !seen.contains(key) {
                seen.insert(key)
                result.append((word.surah, word.ayah))
            }
        }
        self.ayahsOnLine = result
    }
}

struct QuranPage: Identifiable {
    let id: Int
    let lines: [QuranLine]
}

// MARK: - Surah Metadata

struct SurahInfo: Identifiable {
    let id: Int
    let name: String          // transliterated
    let nameSimple: String    // simple English
    let nameArabic: String    // Arabic
    let revelationOrder: Int
    let revelationPlace: String // "makkah" or "madinah"
    let versesCount: Int
    let bismillahPre: Bool
    var startPage: Int = 1    // filled from layout DB
}

// MARK: - Search Result

struct SearchResult: Identifiable {
    var id: String { "\(surah):\(ayah)" }
    let surah: Int
    let ayah: Int
    let verseText: String
    let pageNumber: Int
    let surahName: String
}

// MARK: - Bookmark (supports both page and ayah bookmarks)

struct Bookmark: Identifiable, Codable {
    let id: UUID
    let pageNumber: Int
    let surahName: String
    let surah: Int
    let ayah: Int
    let dateCreated: Date

    // Page bookmark (legacy)
    init(pageNumber: Int, surahName: String) {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.surahName = surahName
        self.surah = 0
        self.ayah = 0
        self.dateCreated = Date()
    }

    // Ayah bookmark
    init(pageNumber: Int, surahName: String, surah: Int, ayah: Int) {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.surahName = surahName
        self.surah = surah
        self.ayah = ayah
        self.dateCreated = Date()
    }

    var isAyahBookmark: Bool {
        surah > 0 && ayah > 0
    }

    var displayLabel: String {
        if isAyahBookmark {
            return "\(surahName) (\(surah):\(ayah))"
        }
        return "\(surahName) — Page \(pageNumber)"
    }
}

// MARK: - Saved Ayah

struct SavedAyah: Identifiable, Codable {
    let id: UUID
    let surah: Int
    let ayah: Int
    let pageNumber: Int
    let surahName: String
    let arabicText: String
    var note: String
    let dateCreated: Date
    var dateUpdated: Date

    var reference: String {
        "\(surah):\(ayah)"
    }

    var hasNote: Bool {
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Reading Plan

enum ReadingPlanKind: String, Codable {
    case khatm
    case customRange
}

enum ReadingPlanStatus: String, Codable {
    case active
    case completed
}

struct ReadingPlan: Codable, Identifiable {
    let id: UUID
    var kind: ReadingPlanKind
    var title: String
    var startPage: Int
    var endPage: Int
    var startDate: Date
    var targetEndDate: Date
    var completedPages: Set<Int>
    var status: ReadingPlanStatus

    var totalPages: Int {
        max(0, endPage - startPage + 1)
    }

    var completedCount: Int {
        completedPages.count
    }

    var remainingPages: Int {
        max(0, totalPages - completedCount)
    }

    var completionPercentage: Double {
        guard totalPages > 0 else { return 0 }
        return Double(completedCount) / Double(totalPages) * 100
    }

    var isComplete: Bool {
        status == .completed || completedCount >= totalPages
    }

    func contains(page: Int) -> Bool {
        page >= startPage && page <= endPage
    }

    func daysRemaining(from date: Date = Date(), calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: date)
        let target = calendar.startOfDay(for: targetEndDate)
        return max(0, calendar.dateComponents([.day], from: today, to: target).day ?? 0)
    }

    func dailyTargetPages(from date: Date = Date(), calendar: Calendar = .current) -> Int {
        let days = max(1, daysRemaining(from: date, calendar: calendar) + 1)
        return max(1, Int(ceil(Double(remainingPages) / Double(days))))
    }
}
