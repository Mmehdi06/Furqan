import Foundation

final class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()

    @Published private(set) var bookmarks: [Bookmark] = []

    private let storageKey = "quran_bookmarks"

    private init() {
        load()
    }

    func addBookmark(page: Int, surahName: String) {
        // Don't duplicate
        guard !bookmarks.contains(where: { $0.pageNumber == page }) else { return }
        let bookmark = Bookmark(pageNumber: page, surahName: surahName)
        bookmarks.append(bookmark)
        bookmarks.sort { $0.pageNumber < $1.pageNumber }
        save()
    }

    func removeBookmark(page: Int) {
        bookmarks.removeAll { $0.pageNumber == page }
        save()
    }

    func isBookmarked(page: Int) -> Bool {
        bookmarks.contains { $0.pageNumber == page }
    }

    func toggleBookmark(page: Int, surahName: String) {
        if isBookmarked(page: page) {
            removeBookmark(page: page)
        } else {
            addBookmark(page: page, surahName: surahName)
        }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Bookmark].self, from: data)
        else { return }
        bookmarks = decoded
    }
}
