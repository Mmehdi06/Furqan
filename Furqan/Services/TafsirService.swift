import Foundation
import SQLite3

final class TafsirService {
    static let shared = TafsirService()

    private var tafsirDB: OpaquePointer?
    private var surahInfoDB: OpaquePointer?
    private var translationDB: OpaquePointer?
    private var currentTranslationDBName: String?

    private init() {}

    /// Open DB connections at startup so first use is instant
    func warmUp() {
        if tafsirDB == nil {
            tafsirDB = openDB("tafsir")
        }
        if surahInfoDB == nil {
            surahInfoDB = openDB("surahInfo")
        }
        loadTranslationDB(for: TranslationManager.shared.current)
    }

    func loadTranslationDB(for language: TranslationLanguage) {
        let dbName = language.dbName
        guard dbName != currentTranslationDBName else { return }
        if let db = translationDB { sqlite3_close(db) }
        translationDB = openDB(dbName)
        currentTranslationDBName = dbName
    }

    deinit {
        if let db = tafsirDB { sqlite3_close(db) }
        if let db = surahInfoDB { sqlite3_close(db) }
        if let db = translationDB { sqlite3_close(db) }
    }

    // MARK: - Tafsir (Ibn Kathir)

    func tafsir(forSurah surah: Int, ayah: Int) -> String? {
        guard let db = tafsirDB else { return nil }

        let ayahKey = "\(surah):\(ayah)"

        // First try exact ayah match
        if let text = queryTafsir(db: db, sql: "SELECT text FROM tafsir WHERE ayah_key = ?;", param: ayahKey) {
            return text
        }

        // If not found, this ayah might be part of a group — search ayah_keys field
        if let text = queryTafsir(db: db, sql: "SELECT text FROM tafsir WHERE ayah_keys LIKE ?;", param: "%\(ayahKey)%") {
            return text
        }

        return nil
    }

    private func queryTafsir(db: OpaquePointer, sql: String, param: String) -> String? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, (param as NSString).utf8String, -1, nil)

        if sqlite3_step(stmt) == SQLITE_ROW,
           let cStr = sqlite3_column_text(stmt, 0) {
            return stripHTML(String(cString: cStr))
        }
        return nil
    }

    // MARK: - Surah Info

    func surahInfo(forSurah surah: Int) -> (name: String, text: String, shortText: String)? {
        guard let db = surahInfoDB else { return nil }

        let sql = "SELECT surah_name, text, short_text FROM surah_infos WHERE surah_number = ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(surah))

        if sqlite3_step(stmt) == SQLITE_ROW {
            let name = sqlite3_column_text(stmt, 0).map { String(cString: $0) } ?? ""
            let text = sqlite3_column_text(stmt, 1).map { stripHTML(String(cString: $0)) } ?? ""
            let shortText = sqlite3_column_text(stmt, 2).map { stripHTML(String(cString: $0)) } ?? ""
            return (name, text, shortText)
        }
        return nil
    }

    // MARK: - Translation

    func translation(forSurah surah: Int, ayah: Int) -> String? {
        guard let db = translationDB else { return nil }

        let sql = "SELECT text FROM translation WHERE sura = ? AND ayah = ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(surah))
        sqlite3_bind_int(stmt, 2, Int32(ayah))

        if sqlite3_step(stmt) == SQLITE_ROW,
           let cStr = sqlite3_column_text(stmt, 0) {
            var text = String(cString: cStr)
            // Remove surrounding quotes if present
            if text.hasPrefix("\"") && text.hasSuffix("\"") {
                text = String(text.dropFirst().dropLast())
            }
            // Remove inline footnotes in [[ ]]
            text = text.replacingOccurrences(
                of: "\\[\\[.*?\\]\\]",
                with: "",
                options: .regularExpression
            )
            // Remove <sup> footnote tags from English translations
            text = text.replacingOccurrences(
                of: "<sup[^>]*>.*?</sup>",
                with: "",
                options: .regularExpression
            )
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    /// Get raw HTML text for surah info (before stripping)
    func surahInfoHTML(forSurah surah: Int) -> String? {
        guard let db = surahInfoDB else { return nil }

        let sql = "SELECT text FROM surah_infos WHERE surah_number = ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(surah))

        if sqlite3_step(stmt) == SQLITE_ROW,
           let cStr = sqlite3_column_text(stmt, 0) {
            return String(cString: cStr)
        }
        return nil
    }

    /// Parse HTML into sections: [(title, body)] for structured display
    func parseSections(from html: String) -> [(title: String, body: String)] {
        var sections: [(String, String)] = []

        // Split by <h2> or <h3> tags
        let pattern = "<h[1-6][^>]*>(.*?)</h[1-6]>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return [("", stripHTML(html))]
        }

        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        if matches.isEmpty {
            return [("", stripHTML(html))]
        }

        for (i, match) in matches.enumerated() {
            let title = nsHTML.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)

            let bodyStart = match.range.upperBound
            let bodyEnd = (i + 1 < matches.count) ? matches[i + 1].range.location : nsHTML.length
            let bodyHTML = nsHTML.substring(with: NSRange(location: bodyStart, length: bodyEnd - bodyStart))
            let body = stripHTML(bodyHTML).trimmingCharacters(in: .whitespacesAndNewlines)

            if !body.isEmpty {
                sections.append((title, body))
            }
        }

        return sections
    }

    // MARK: - Helpers

    private func openDB(_ name: String) -> OpaquePointer? {
        guard let path = Bundle.main.path(forResource: name, ofType: "db") else { return nil }
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return nil }
        return db
    }

    private func stripHTML(_ html: String) -> String {
        // Convert headers to uppercase with line breaks
        var text = html.replacingOccurrences(
            of: "<h[1-6][^>]*>(.*?)</h[1-6]>",
            with: "\n\n$1\n",
            options: .regularExpression
        )
        // Convert paragraph breaks
        text = text.replacingOccurrences(of: "</p>", with: "\n\n")
        // Strip remaining tags
        text = text.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        // Remove inline footnotes in [[ ]]
        text = text.replacingOccurrences(
            of: "\\[\\[.*?\\]\\]",
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(of: "\\s*\\n\\s*\\n\\s*", with: "\n\n", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text
    }
}
