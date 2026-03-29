import SwiftUI

struct BookmarksView: View {
    @ObservedObject var bookmarkManager: BookmarkManager
    let onSelect: (Int, Int, Int) -> Void  // (page, surah, ayah) — surah/ayah = 0 for page bookmarks
    @Environment(\.dismiss) private var dismiss
    @Environment(\.readingTheme) private var theme

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
                        fallbackFill: cardFill,
                        fallbackStroke: cardStroke
                    )
                    .padding(20)
                } else {
                    List {
                        if !ayahBookmarks.isEmpty {
                            Section {
                                ForEach(ayahBookmarks) { bookmark in
                                    Button {
                                        onSelect(bookmark.pageNumber, bookmark.surah, bookmark.ayah)
                                        dismiss()
                                    } label: {
                                        ayahBookmarkRow(bookmark)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                    .listRowBackground(Color.clear)
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        let bm = ayahBookmarks[index]
                                        bookmarkManager.removeAyahBookmark(surah: bm.surah, ayah: bm.ayah)
                                    }
                                }
                            } header: {
                                sectionHeader(
                                    title: "Ayah Bookmarks",
                                    subtitle: "Saved verses"
                                )
                            }
                        }

                        if !pageBookmarks.isEmpty {
                            Section {
                                ForEach(pageBookmarks) { bookmark in
                                    Button {
                                        onSelect(bookmark.pageNumber, 0, 0)
                                        dismiss()
                                    } label: {
                                        pageBookmarkRow(bookmark)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                    .listRowBackground(Color.clear)
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        let bm = pageBookmarks[index]
                                        bookmarkManager.removeBookmark(page: bm.pageNumber)
                                    }
                                }
                            } header: {
                                sectionHeader(
                                    title: "Page Bookmarks",
                                    subtitle: "Saved positions"
                                )
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(theme.pageBackground)
                    .accessibilityIdentifier("bookmarksList")
                }
            }
            .background(theme.pageBackground.ignoresSafeArea())
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func ayahBookmarkRow(_ bookmark: Bookmark) -> some View {
        bookmarkRowCard(iconColor: .orange) {
            HStack {
            Image(systemName: "bookmark.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.displayLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.textColor)
                    Text("Page \(bookmark.pageNumber)")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()

                Text(bookmark.dateCreated, style: .date)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(theme.tertiaryTextColor)
            }
        }
    }

    private func pageBookmarkRow(_ bookmark: Bookmark) -> some View {
        bookmarkRowCard(iconColor: .blue) {
            HStack {
            Image(systemName: "bookmark.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.surahName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.textColor)
                    Text("Page \(bookmark.pageNumber)")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()

                Text(bookmark.dateCreated, style: .date)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(theme.tertiaryTextColor)
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textColor)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .textCase(nil)
        .padding(.top, 8)
    }

    private func bookmarkRowCard<Content: View>(iconColor: Color, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .adaptiveGlass(
            in: RoundedRectangle(cornerRadius: 22, style: .continuous),
            tint: iconColor.opacity(0.08),
            fallbackFill: cardFill,
            fallbackStroke: cardStroke
        )
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var cardFill: AnyShapeStyle {
        switch theme {
        case .amoled:
            return AnyShapeStyle(Color.white.opacity(0.05))
        case .sepia:
            return AnyShapeStyle(theme.pageBackground.opacity(0.94))
        default:
            return AnyShapeStyle(.thinMaterial)
        }
    }

    private var cardStroke: Color {
        switch theme {
        case .light:
            return .black.opacity(0.06)
        case .dark:
            return .white.opacity(0.08)
        case .sepia:
            return Color(red: 0.55, green: 0.45, blue: 0.33).opacity(0.18)
        case .amoled:
            return .white.opacity(0.05)
        }
    }
}
