import SwiftUI

struct BookmarksView: View {
    @ObservedObject var bookmarkManager: BookmarkManager
    let onSelect: (Int, Int, Int) -> Void  // (page, surah, ayah) — surah/ayah = 0 for page bookmarks
    @Environment(\.dismiss) private var dismiss

    private var accentTint: Color {
        pageBookmarks.isEmpty ? .orange.opacity(0.18) : .blue.opacity(0.16)
    }

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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(24)
                    .adaptiveGlass(
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous),
                        tint: accentTint,
                        fallbackFill: AnyShapeStyle(.thinMaterial)
                    )
                    .padding(20)
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
                                    .buttonStyle(.plain)
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
                                    .buttonStyle(.plain)
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
                    .scrollContentBackground(.hidden)
                    .accessibilityIdentifier("bookmarksList")
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
