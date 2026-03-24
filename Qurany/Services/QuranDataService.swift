import Foundation
import SQLite3

final class QuranDataService {
    static let shared = QuranDataService()

    private var contentDB: OpaquePointer?
    private var layoutDB: OpaquePointer?
    private var metadataDB: OpaquePointer?

    private(set) var pages: [QuranPage] = []
    private(set) var surahs: [SurahInfo] = []

    /// Map from surah number to start page
    private(set) var surahStartPages: [Int: Int] = [:]

    private init() {}

    func loadAll() {
        openDatabases()
        let words = loadWords()
        pages = buildPages(words: words)
        surahStartPages = loadSurahStartPages()
        surahs = loadSurahMetadata()
        closeDatabases()
    }

    // MARK: - Database Access

    private func openDatabases() {
        contentDB = openDatabase(named: "qpc-v4", ext: "db")
        layoutDB = openDatabase(named: "mushafLayout", ext: "db")
        metadataDB = openDatabase(named: "surahMetadata", ext: "db")
    }

    private func closeDatabases() {
        if let db = contentDB { sqlite3_close(db); contentDB = nil }
        if let db = layoutDB { sqlite3_close(db); layoutDB = nil }
        if let db = metadataDB { sqlite3_close(db); metadataDB = nil }
    }

    private func openDatabase(named name: String, ext: String) -> OpaquePointer? {
        guard let path = Bundle.main.path(forResource: name, ofType: ext) else {
            print("Database \(name).\(ext) not found in bundle")
            return nil
        }
        var db: OpaquePointer?
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            print("Failed to open \(name).\(ext)")
            return nil
        }
        return db
    }

    // MARK: - Load Words

    private func loadWords() -> [Int: QuranWord] {
        guard let db = contentDB else { return [:] }
        var result: [Int: QuranWord] = [:]
        let query = "SELECT id, location, surah, ayah, word, text FROM words;"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return [:] }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let location = String(cString: sqlite3_column_text(stmt, 1))
            let surah = Int(sqlite3_column_int(stmt, 2))
            let ayah = Int(sqlite3_column_int(stmt, 3))
            let wordPos = Int(sqlite3_column_int(stmt, 4))
            let text = String(cString: sqlite3_column_text(stmt, 5))

            result[id] = QuranWord(
                id: id,
                location: location,
                surah: surah,
                ayah: ayah,
                wordPosition: wordPos,
                text: text
            )
        }
        return result
    }

    // MARK: - Load Surah Start Pages

    private func loadSurahStartPages() -> [Int: Int] {
        guard let db = layoutDB else { return [:] }
        let query = "SELECT surah_number, MIN(page_number) FROM pages WHERE line_type='surah_name' AND surah_number IS NOT NULL GROUP BY surah_number;"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return [:] }
        defer { sqlite3_finalize(stmt) }

        var result: [Int: Int] = [:]
        while sqlite3_step(stmt) == SQLITE_ROW {
            let surah = Int(sqlite3_column_int(stmt, 0))
            let page = Int(sqlite3_column_int(stmt, 1))
            result[surah] = page
        }
        return result
    }

    // MARK: - Load Surah Metadata

    private func loadSurahMetadata() -> [SurahInfo] {
        guard let db = metadataDB else { return [] }
        let query = "SELECT id, name, name_simple, name_arabic, revelation_order, revelation_place, verses_count, bismillah_pre FROM chapters ORDER BY id;"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var result: [SurahInfo] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let nameSimple = String(cString: sqlite3_column_text(stmt, 2))
            let nameArabic = String(cString: sqlite3_column_text(stmt, 3))
            let revelationOrder = Int(sqlite3_column_int(stmt, 4))
            let revelationPlace = String(cString: sqlite3_column_text(stmt, 5))
            let versesCount = Int(sqlite3_column_int(stmt, 6))
            let bismillahPre = sqlite3_column_int(stmt, 7) != 0

            var surah = SurahInfo(
                id: id,
                name: name,
                nameSimple: nameSimple,
                nameArabic: nameArabic,
                revelationOrder: revelationOrder,
                revelationPlace: revelationPlace,
                versesCount: versesCount,
                bismillahPre: bismillahPre
            )
            surah.startPage = surahStartPages[id] ?? 1
            result.append(surah)
        }
        return result
    }

    // MARK: - Build Pages from Layout

    private func buildPages(words: [Int: QuranWord]) -> [QuranPage] {
        guard let db = layoutDB else { return [] }
        let query = "SELECT page_number, line_number, line_type, is_centered, first_word_id, last_word_id, surah_number FROM pages ORDER BY page_number, line_number;"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var pageDict: [Int: [QuranLine]] = [:]

        while sqlite3_step(stmt) == SQLITE_ROW {
            let pageNum = Int(sqlite3_column_int(stmt, 0))
            let lineNum = Int(sqlite3_column_int(stmt, 1))
            let lineTypeStr = String(cString: sqlite3_column_text(stmt, 2))
            let isCentered = sqlite3_column_int(stmt, 3) != 0

            let firstWordID: Int? = sqlite3_column_type(stmt, 4) != SQLITE_NULL
                ? Int(sqlite3_column_int(stmt, 4)) : nil
            let lastWordID: Int? = sqlite3_column_type(stmt, 5) != SQLITE_NULL
                ? Int(sqlite3_column_int(stmt, 5)) : nil
            let surahNumber: Int? = sqlite3_column_type(stmt, 6) != SQLITE_NULL
                ? Int(sqlite3_column_int(stmt, 6)) : nil

            let lineType = LineType(rawValue: lineTypeStr) ?? .ayah

            var lineWords: [QuranWord] = []
            if let first = firstWordID, let last = lastWordID {
                for wordID in first...last {
                    if let word = words[wordID] {
                        lineWords.append(word)
                    }
                }
            }

            let line = QuranLine(
                id: "\(pageNum)_\(lineNum)",
                lineNumber: lineNum,
                lineType: lineType,
                isCentered: isCentered,
                surahNumber: surahNumber,
                words: lineWords
            )

            pageDict[pageNum, default: []].append(line)
        }

        return pageDict.keys.sorted().map { pageNum in
            QuranPage(id: pageNum, lines: pageDict[pageNum] ?? [])
        }
    }

    // MARK: - Helpers

    /// Find which surah a given page belongs to
    func surahName(forPage page: Int) -> String {
        // Find the surah whose start page is <= this page
        if let surah = surahs.last(where: { $0.startPage <= page }) {
            return surah.nameArabic
        }
        return ""
    }
}
