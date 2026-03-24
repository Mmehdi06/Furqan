import Foundation

final class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()

    @Published private(set) var bookmarks: [Bookmark] = []

    private let storageKey = "quran_bookmarks_v2"

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
        bookmarks.removeAll { $0.surah == surah && $0.ayah == ayah && $0.isAyahBookmark }
        save()
    }

    func isAyahBookmarked(surah: Int, ayah: Int) -> Bool {
        bookmarks.contains { $0.surah == surah && $0.ayah == ayah && $0.isAyahBookmark }
    }

    func toggleAyahBookmark(page: Int, surahName: String, surah: Int, ayah: Int) {
        if isAyahBookmarked(surah: surah, ayah: ayah) {
            removeAyahBookmark(surah: surah, ayah: ayah)
        } else {
            addAyahBookmark(page: page, surahName: surahName, surah: surah, ayah: ayah)
        }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        // Try v2 first, then fall back to v1
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = decoded
        } else if let data = UserDefaults.standard.data(forKey: "quran_bookmarks"),
                  let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = decoded
            save() // Migrate to v2 key
        }
    }
}
