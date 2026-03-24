import SwiftUI

struct BookmarksView: View {
    @ObservedObject var bookmarkManager: BookmarkManager
    let onSelect: (Int, Int, Int) -> Void  // (page, surah, ayah) — surah/ayah = 0 for page bookmarks
    @Environment(\.dismiss) private var dismiss

    private var pageBookmarks: [Bookmark] {
        bookmarkManager.bookmarks.filter { !$0.isAyahBookmark }
    }

    private var ayahBookmarks: [Bookmark] {
        bookmarkManager.bookmarks.filter { $0.isAyahBookmark }
    }

    var body: some View {
        NavigationStack {
            Group {
                if bookmarkManager.bookmarks.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark",
                        description: Text("Long press on any ayah to add a bookmark")
                    )
                } else {
                    List {
                        if !ayahBookmarks.isEmpty {
                            Section("Ayah Bookmarks") {
                                ForEach(ayahBookmarks) { bookmark in
                                    Button {
                                        onSelect(bookmark.pageNumber, bookmark.surah, bookmark.ayah)
                                        dismiss()
                                    } label: {
                                        ayahBookmarkRow(bookmark)
                                    }
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        let bm = ayahBookmarks[index]
                                        bookmarkManager.removeAyahBookmark(surah: bm.surah, ayah: bm.ayah)
                                    }
                                }
                            }
                        }

                        if !pageBookmarks.isEmpty {
                            Section("Page Bookmarks") {
                                ForEach(pageBookmarks) { bookmark in
                                    Button {
                                        onSelect(bookmark.pageNumber, 0, 0)
                                        dismiss()
                                    } label: {
                                        pageBookmarkRow(bookmark)
                                    }
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        let bm = pageBookmarks[index]
                                        bookmarkManager.removeBookmark(page: bm.pageNumber)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func ayahBookmarkRow(_ bookmark: Bookmark) -> some View {
        HStack {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.displayLabel)
                    .font(.system(size: 15, weight: .medium))
                Text("Page \(bookmark.pageNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(bookmark.dateCreated, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func pageBookmarkRow(_ bookmark: Bookmark) -> some View {
        HStack {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(.blue)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.surahName)
                    .font(.system(size: 15, weight: .medium))
                Text("Page \(bookmark.pageNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(bookmark.dateCreated, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
