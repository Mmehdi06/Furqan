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

    // Tafsir & Surah Info sheets
    @State private var tafsirTarget: (surah: Int, ayah: Int)?
    @State private var surahInfoTarget: Int?

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
                    MushafPageView(
                        page: page,
                        highlightedAyah: highlightedAyah,
                        onAyahAction: { action in
                            handleAyahAction(action)
                        }
                    )
                    .tag(page.id)
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

                HStack {
                    Button {
                        showSurahIndex = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }

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

                    Text("\(currentPage)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial, in: Capsule())

                    Spacer()

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

            // Toast
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
            BookmarksView(bookmarkManager: bookmarkManager) { page, surah, ayah in
                currentPage = page
                if surah > 0 && ayah > 0 {
                    highlightAyah(surah: surah, ayah: ayah)
                }
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView { page, surah, ayah in
                currentPage = page
                highlightAyah(surah: surah, ayah: ayah)
            }
        }
        .sheet(item: Binding(
            get: { tafsirTarget.map { TafsirTarget(surah: $0.surah, ayah: $0.ayah) } },
            set: { tafsirTarget = $0.map { ($0.surah, $0.ayah) } }
        )) { target in
            TafsirView(surah: target.surah, ayah: target.ayah)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: Binding(
            get: { surahInfoTarget.map { SurahInfoTarget(surah: $0) } },
            set: { surahInfoTarget = $0?.surah }
        )) { target in
            SurahInfoView(surahNumber: target.surah)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Actions

    private func handleAyahAction(_ action: AyahAction) {
        switch action {
        case .showTafsir(let surah, let ayah):
            tafsirTarget = (surah, ayah)

        case .showSurahInfo(let surah):
            surahInfoTarget = surah

        case .toggleBookmark(let surah, let ayah, let page):
            let surahName = QuranDataService.shared.surahName(forPage: page)
            bookmarkManager.toggleAyahBookmark(page: page, surahName: surahName, surah: surah, ayah: ayah)
            let isNowBookmarked = bookmarkManager.isAyahBookmarked(surah: surah, ayah: ayah)
            toastMessage = isNowBookmarked
                ? "Bookmarked \(surah):\(ayah)"
                : "Removed bookmark"
            withAnimation { showBookmarkToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showBookmarkToast = false }
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

// MARK: - Helper Types

private struct TafsirTarget: Identifiable {
    let id = UUID()
    let surah: Int
    let ayah: Int
}

private struct SurahInfoTarget: Identifiable {
    let id = UUID()
    let surah: Int
}
