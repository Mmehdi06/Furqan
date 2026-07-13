import Foundation

final class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()

    @Published private(set) var bookmarks: [Bookmark] = []
    @Published private(set) var savedAyahs: [SavedAyah] = []

    private let storageKey = "quran_bookmarks_v2"
    private let savedAyahsKey = "saved_ayahs_v1"

    private init() {
        load()
    }

    // MARK: - Page Bookmarks

    func addBookmark(page: Int, surahName: String) {
        guard !bookmarks.contains(where: { $0.pageNumber == page && !$0.isAyahBookmark }) else { return }
        let bookmark = Bookmark(pageNumber: page, surahName: surahName)
        bookmarks.append(bookmark)
        bookmarks.sort { $0.pageNumber < $1.pageNumber }
        save()
    }

    func removeBookmark(page: Int) {
        bookmarks.removeAll { $0.pageNumber == page && !$0.isAyahBookmark }
        save()
    }

    func isBookmarked(page: Int) -> Bool {
        bookmarks.contains { $0.pageNumber == page && !$0.isAyahBookmark }
    }

    func toggleBookmark(page: Int, surahName: String) {
        if isBookmarked(page: page) {
            removeBookmark(page: page)
        } else {
            addBookmark(page: page, surahName: surahName)
        }
    }

    // MARK: - Ayah Bookmarks

    func addAyahBookmark(page: Int, surahName: String, surah: Int, ayah: Int) {
        saveAyah(page: page, surahName: surahName, surah: surah, ayah: ayah)
        guard !isAyahBookmarked(surah: surah, ayah: ayah) else { return }
        let bookmark = Bookmark(pageNumber: page, surahName: surahName, surah: surah, ayah: ayah)
        bookmarks.append(bookmark)
        bookmarks.sort {
            if $0.surah != $1.surah { return $0.surah < $1.surah }
            return $0.ayah < $1.ayah
        }
        save()
    }

    func removeAyahBookmark(surah: Int, ayah: Int) {
        removeSavedAyah(surah: surah, ayah: ayah)
        bookmarks.removeAll { $0.surah == surah && $0.ayah == ayah && $0.isAyahBookmark }
        save()
    }

    func isAyahBookmarked(surah: Int, ayah: Int) -> Bool {
        isSavedAyah(surah: surah, ayah: ayah)
    }

    func toggleAyahBookmark(page: Int, surahName: String, surah: Int, ayah: Int) {
        if isAyahBookmarked(surah: surah, ayah: ayah) {
            removeAyahBookmark(surah: surah, ayah: ayah)
        } else {
            addAyahBookmark(page: page, surahName: surahName, surah: surah, ayah: ayah)
        }
    }

    // MARK: - Saved Ayahs

    var notes: [SavedAyah] {
        savedAyahs.filter(\.hasNote)
    }

    var ayahsWithoutNotes: [SavedAyah] {
        savedAyahs.filter { !$0.hasNote }
    }

    func savedAyah(surah: Int, ayah: Int) -> SavedAyah? {
        savedAyahs.first { $0.surah == surah && $0.ayah == ayah }
    }

    func isSavedAyah(surah: Int, ayah: Int) -> Bool {
        savedAyahIndex(surah: surah, ayah: ayah) != nil
    }

    @discardableResult
    func saveAyah(page: Int, surahName: String, surah: Int, ayah: Int, note: String = "") -> SavedAyah {
        if let index = savedAyahIndex(surah: surah, ayah: ayah) {
            if !note.isEmpty {
                savedAyahs[index].note = note
                savedAyahs[index].dateUpdated = Date()
                saveSavedAyahs()
            }
            return savedAyahs[index]
        }

        let arabicText = QuranSearchService.shared.verseText(surah: surah, ayah: ayah) ?? ""
        let saved = SavedAyah(
            id: UUID(),
            surah: surah,
            ayah: ayah,
            pageNumber: page,
            surahName: surahName,
            arabicText: arabicText,
            note: note,
            dateCreated: Date(),
            dateUpdated: Date()
        )
        savedAyahs.append(saved)
        sortSavedAyahs()
        saveSavedAyahs()
        return saved
    }

    func removeSavedAyah(surah: Int, ayah: Int) {
        savedAyahs.removeAll { $0.surah == surah && $0.ayah == ayah }
        saveSavedAyahs()
    }

    func updateNote(surah: Int, ayah: Int, page: Int, surahName: String, note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = savedAyahIndex(surah: surah, ayah: ayah) {
            savedAyahs[index].note = trimmed
            savedAyahs[index].dateUpdated = Date()
            sortSavedAyahs()
            saveSavedAyahs()
        } else {
            _ = saveAyah(page: page, surahName: surahName, surah: surah, ayah: ayah, note: trimmed)
        }
    }

    func clearNote(surah: Int, ayah: Int) {
        guard let index = savedAyahIndex(surah: surah, ayah: ayah) else { return }
        savedAyahs[index].note = ""
        savedAyahs[index].dateUpdated = Date()
        saveSavedAyahs()
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        loadSavedAyahs()

        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = decoded
            migrateBookmarksToSavedAyahs(decoded)
        } else if let data = UserDefaults.standard.data(forKey: "quran_bookmarks"),
                  let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = decoded
            migrateBookmarksToSavedAyahs(decoded)
            save() // Migrate to v2 key
        }
    }

    private func saveSavedAyahs() {
        if let data = try? JSONEncoder().encode(savedAyahs) {
            UserDefaults.standard.set(data, forKey: savedAyahsKey)
        }
    }

    private func loadSavedAyahs() {
        guard let data = UserDefaults.standard.data(forKey: savedAyahsKey),
              let decoded = try? JSONDecoder().decode([SavedAyah].self, from: data)
        else { return }
        savedAyahs = decoded
        sortSavedAyahs()
    }

    private func migrateBookmarksToSavedAyahs(_ legacyBookmarks: [Bookmark]) {
        guard savedAyahs.isEmpty else { return }
        savedAyahs = legacyBookmarks
            .filter(\.isAyahBookmark)
            .map { bookmark in
                SavedAyah(
                    id: bookmark.id,
                    surah: bookmark.surah,
                    ayah: bookmark.ayah,
                    pageNumber: bookmark.pageNumber,
                    surahName: bookmark.surahName,
                    arabicText: QuranSearchService.shared.verseText(surah: bookmark.surah, ayah: bookmark.ayah) ?? "",
                    note: "",
                    dateCreated: bookmark.dateCreated,
                    dateUpdated: bookmark.dateCreated
                )
            }
        sortSavedAyahs()
        saveSavedAyahs()
    }

    private func savedAyahIndex(surah: Int, ayah: Int) -> Int? {
        savedAyahs.firstIndex { $0.surah == surah && $0.ayah == ayah }
    }

    private func sortSavedAyahs() {
        savedAyahs.sort {
            if $0.hasNote != $1.hasNote { return $0.hasNote && !$1.hasNote }
            if $0.surah != $1.surah { return $0.surah < $1.surah }
            return $0.ayah < $1.ayah
        }
    }
}
