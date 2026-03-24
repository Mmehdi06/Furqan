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

// MARK: - Bookmark

struct Bookmark: Identifiable, Codable {
    let id: UUID
    let pageNumber: Int
    let surahName: String
    let dateCreated: Date

    init(pageNumber: Int, surahName: String) {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.surahName = surahName
        self.dateCreated = Date()
    }
}
