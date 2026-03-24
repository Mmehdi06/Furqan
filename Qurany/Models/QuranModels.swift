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

    /// Unique ayahs present on this line
    var ayahsOnLine: [(surah: Int, ayah: Int)] {
        var seen = Set<String>()
        var result: [(surah: Int, ayah: Int)] = []
        for word in words {
            let key = "\(word.surah):\(word.ayah)"
            if !seen.contains(key) {
                seen.insert(key)
                result.append((word.surah, word.ayah))
            }
        }
        return result
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
    let id = UUID()
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
