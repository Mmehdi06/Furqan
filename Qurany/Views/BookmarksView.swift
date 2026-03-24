import SwiftUI

struct BookmarksView: View {
    @ObservedObject var bookmarkManager: BookmarkManager
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if bookmarkManager.bookmarks.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark",
                        description: Text("Long press on any page to add a bookmark")
                    )
                } else {
                    List {
                        ForEach(bookmarkManager.bookmarks) { bookmark in
                            Button {
                                onSelect(bookmark.pageNumber)
                                dismiss()
                            } label: {
                                bookmarkRow(bookmark)
                            }
                        }
                        .onDelete(perform: deleteBookmarks)
                    }
                    .listStyle(.plain)
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

    private func bookmarkRow(_ bookmark: Bookmark) -> some View {
        HStack {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.surahName)
                    .font(.system(size: 16, weight: .medium))
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

    private func deleteBookmarks(at offsets: IndexSet) {
        for index in offsets {
            let bookmark = bookmarkManager.bookmarks[index]
            bookmarkManager.removeBookmark(page: bookmark.pageNumber)
        }
    }
}
