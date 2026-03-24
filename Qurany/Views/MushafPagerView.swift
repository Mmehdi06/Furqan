import SwiftUI

struct AyahHighlight: Equatable {
    let surah: Int
    let ayah: Int
}

struct MushafPagerView: View {
    let pages: [QuranPage]
    let surahs: [SurahInfo]

    @State private var currentPage: Int
    @State private var showSurahIndex = false
    @State private var showBookmarks = false
    @State private var showSearch = false
    @State private var showBookmarkToast = false
    @State private var toastMessage = ""
    @State private var highlightedAyah: AyahHighlight?

    @StateObject private var bookmarkManager = BookmarkManager.shared

    private let lastPageKey = "quran_last_page"

    init(pages: [QuranPage], surahs: [SurahInfo]) {
        self.pages = pages
        self.surahs = surahs
        let savedPage = UserDefaults.standard.integer(forKey: "quran_last_page")
        _currentPage = State(initialValue: savedPage > 0 ? savedPage : 1)
    }

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                ForEach(pages) { page in
                    MushafPageView(page: page, highlightedAyah: highlightedAyah)
                        .tag(page.id)
                        .onLongPressGesture {
                            let surahName = QuranDataService.shared.surahName(forPage: page.id)
                            bookmarkManager.toggleBookmark(page: page.id, surahName: surahName)
                            toastMessage = bookmarkManager.isBookmarked(page: page.id)
                                ? "Bookmarked page \(page.id)"
                                : "Removed bookmark"
                            withAnimation { showBookmarkToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { showBookmarkToast = false }
                            }
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .environment(\.layoutDirection, .rightToLeft)
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: currentPage) { _, newPage in
                UserDefaults.standard.set(newPage, forKey: lastPageKey)
            }

            // Overlay UI
            VStack {
                Spacer()

                // Bottom bar
                HStack {
                    // Surah index button
                    Button {
                        showSurahIndex = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    // Search button
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Spacer()

                    // Page number
                    Text("\(currentPage)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial, in: Capsule())

                    Spacer()

                    // Bookmarks button
                    Button {
                        showBookmarks = true
                    } label: {
                        Image(systemName: bookmarkManager.isBookmarked(page: currentPage) ? "bookmark.fill" : "bookmark")
                            .font(.body)
                            .foregroundStyle(bookmarkManager.isBookmarked(page: currentPage) ? .orange : .secondary)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            // Bookmark toast
            if showBookmarkToast {
                VStack {
                    Text(toastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.75), in: Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 60)
            }
        }
        .sheet(isPresented: $showSurahIndex) {
            SurahIndexView(surahs: surahs) { page in
                currentPage = page
            }
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView(bookmarkManager: bookmarkManager) { page in
                currentPage = page
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView { page, surah, ayah in
                currentPage = page
                highlightAyah(surah: surah, ayah: ayah)
            }
        }
    }

    // MARK: - Ayah Highlight

    private func highlightAyah(surah: Int, ayah: Int) {
        withAnimation(.easeIn(duration: 0.3)) {
            highlightedAyah = AyahHighlight(surah: surah, ayah: ayah)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                highlightedAyah = nil
            }
        }
    }
}
