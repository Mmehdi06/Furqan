import Foundation
import SQLite3

final class QuranDataService {
    static let shared = QuranDataService()

    private var contentDB: OpaquePointer?
    private var layoutDB: OpaquePointer?
    private(set) var pages: [QuranPage] = []

    private init() {}

    func loadAll() {
        openDatabases()
        let words = loadWords()
        pages = buildPages(words: words)
        closeDatabases()
    }

    // MARK: - Database Access

    private func openDatabases() {
        contentDB = openDatabase(named: "qpc-v4", ext: "db")
        layoutDB = openDatabase(named: "mushafLayout", ext: "db")
    }

    private func closeDatabases() {
        if let db = contentDB { sqlite3_close(db); contentDB = nil }
        if let db = layoutDB { sqlite3_close(db); layoutDB = nil }
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
}
