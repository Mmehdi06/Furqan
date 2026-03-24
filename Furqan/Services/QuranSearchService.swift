import Foundation
import SQLite3

final class QuranSearchService {
    static let shared = QuranSearchService()

    private var db: OpaquePointer?

    private init() {
        openDatabase()
    }

    deinit {
        if let db = db { sqlite3_close(db) }
    }

    // MARK: - Database

    private func openDatabase() {
        guard let path = Bundle.main.path(forResource: "quranSearchText", ofType: "db") else {
            print("quranSearchText.db not found")
            return
        }
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            print("Failed to open quranSearchText.db")
        }
    }

    // MARK: - Search

    /// Search verses by Arabic text query. Returns up to `limit` results.
    /// Supports both exact (with diacritics) and normalized (without diacritics) search.
    func search(query: String, limit: Int = 50) -> [SearchResult] {
        guard let db = db, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = normalizeArabic(trimmed)

        // Search both exact text and normalized text
        let sql = """
            SELECT v.surah, v.ayah, v.verse_text, v.first_word_id
            FROM verses v
            WHERE v.verse_text LIKE ? OR v.verse_normalized LIKE ?
            ORDER BY v.surah, v.ayah
            LIMIT ?
            """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        let exactPattern = "%\(trimmed)%"
        let normPattern = "%\(normalized)%"
        sqlite3_bind_text(stmt, 1, (exactPattern as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (normPattern as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 3, Int32(limit))

        var results: [SearchResult] = []
        let surahs = QuranDataService.shared.surahs

        while sqlite3_step(stmt) == SQLITE_ROW {
            let surah = Int(sqlite3_column_int(stmt, 0))
            let ayah = Int(sqlite3_column_int(stmt, 1))
            let verseText = String(cString: sqlite3_column_text(stmt, 2))
            let firstWordId = Int(sqlite3_column_int(stmt, 3))

            let page = pageNumber(forWordId: firstWordId)
            let surahName = surahs.first(where: { $0.id == surah })?.nameArabic ?? ""

            results.append(SearchResult(
                surah: surah,
                ayah: ayah,
                verseText: verseText,
                pageNumber: page,
                surahName: surahName
            ))
        }

        return results
    }

    // MARK: - Page Lookup

    private func pageNumber(forWordId wordId: Int) -> Int {
        guard let db = db else { return 1 }

        let sql = "SELECT page_number FROM word_pages WHERE first_word_id <= ? AND last_word_id >= ? LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 1 }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(wordId))
        sqlite3_bind_int(stmt, 2, Int32(wordId))

        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        return 1
    }

    // MARK: - Arabic Normalization

    /// Strip diacritics, normalize alef variants, teh marbuta, tatweel
    private func normalizeArabic(_ text: String) -> String {
        var result = text

        // Remove Arabic diacritics (tashkeel)
        let tashkeel = CharacterSet(charactersIn: "\u{0610}"..."\u{061A}")
            .union(CharacterSet(charactersIn: "\u{064B}"..."\u{065F}"))
            .union(CharacterSet(charactersIn: "\u{0670}"))
            .union(CharacterSet(charactersIn: "\u{06D6}"..."\u{06ED}"))
        result = String(result.unicodeScalars.filter { !tashkeel.contains($0) })

        // Normalize alef variants -> plain alef
        let alefMap: [Character: Character] = [
            "\u{0622}": "\u{0627}", // آ -> ا
            "\u{0623}": "\u{0627}", // أ -> ا
            "\u{0625}": "\u{0627}", // إ -> ا
            "\u{0671}": "\u{0627}", // ٱ -> ا
        ]
        result = String(result.map { alefMap[$0] ?? $0 })

        // Normalize teh marbuta -> heh
        result = result.replacingOccurrences(of: "\u{0629}", with: "\u{0647}")

        // Remove tatweel
        result = result.replacingOccurrences(of: "\u{0640}", with: "")

        // Remove Quran-specific marks
        let quranMarks = CharacterSet(charactersIn: "\u{06D0}"..."\u{06FF}")
        result = String(result.unicodeScalars.filter { !quranMarks.contains($0) })

        // Collapse whitespace
        result = result.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return result
    }
}
