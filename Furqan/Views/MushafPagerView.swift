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

    // Tafsir, Translation & Surah Info sheets
    @State private var tafsirTarget: (surah: Int, ayah: Int)?
    @State private var translationTarget: (surah: Int, ayah: Int)?
    @State private var surahInfoTarget: Int?
    @State private var showSettings = false

    @StateObject private var bookmarkManager = BookmarkManager.shared
    @StateObject private var translationManager = TranslationManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.readingTheme) private var theme

    private let lastPageKey = "quran_last_page"

    private var currentSurahName: String {
        surahs.last(where: { $0.startPage <= currentPage })?.nameSimple ?? ""
    }

    init(pages: [QuranPage], surahs: [SurahInfo]) {
        self.pages = pages
        self.surahs = surahs
        let savedPage = UserDefaults.standard.integer(forKey: "quran_last_page")
        _currentPage = State(initialValue: savedPage > 0 ? savedPage : 1)
    }

    var body: some View {
        ZStack {
            theme.pageBackground
                .ignoresSafeArea()

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
            .accessibilityIdentifier("mushafPager")
            .tabViewStyle(.page(indexDisplayMode: .never))
            .environment(\.layoutDirection, .rightToLeft)
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: currentPage) { _, newPage in
                UserDefaults.standard.set(newPage, forKey: lastPageKey)
            }

            // Toolbar overlay
            VStack {
                Spacer()

                bottomToolbar
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
                        .adaptiveGlass(
                            in: Capsule(),
                            tint: .black.opacity(theme == .amoled ? 0.35 : 0.2),
                            fallbackFill: AnyShapeStyle(.regularMaterial)
                        )
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
        .sheet(isPresented: $showSettings) {
            SettingsView(themeManager: themeManager, translationManager: translationManager)
                .presentationDetents([.large])
        }
        .sheet(item: Binding(
            get: { tafsirTarget.map { TafsirTarget(surah: $0.surah, ayah: $0.ayah) } },
            set: { tafsirTarget = $0.map { ($0.surah, $0.ayah) } }
        )) { target in
            TafsirView(surah: target.surah, ayah: target.ayah)
                .presentationDetents( [.large])
        }
        .sheet(item: Binding(
            get: { translationTarget.map { TranslationTarget(surah: $0.surah, ayah: $0.ayah) } },
            set: { translationTarget = $0.map { ($0.surah, $0.ayah) } }
        )) { target in
            TranslationView(surah: target.surah, ayah: target.ayah)
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
        case .showTranslation(let surah, let ayah):
            translationTarget = (surah, ayah)

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
        highlightedAyah = AyahHighlight(surah: surah, ayah: ayah)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            highlightedAyah = nil
        }
    }

    private var bottomToolbar: some View {
        HStack {
            toolbarCluster {
                toolbarButton(
                    systemName: "list.bullet",
                    accessibilityIdentifier: "surahIndexButton"
                ) {
                    showSurahIndex = true
                }

                toolbarButton(
                    systemName: "magnifyingglass",
                    accessibilityIdentifier: "searchButton"
                ) {
                    showSearch = true
                }
            }

            Spacer(minLength: 12)

            pageInfoChip

            Spacer(minLength: 12)

            toolbarCluster {
                toolbarButton(
                    systemName: "gearshape",
                    accessibilityIdentifier: "settingsButton"
                ) {
                    showSettings = true
                }

                toolbarButton(
                    systemName: bookmarkManager.isBookmarked(page: currentPage) ? "bookmark.fill" : "bookmark",
                    tint: bookmarkManager.isBookmarked(page: currentPage) ? .orange : nil,
                    accessibilityIdentifier: "bookmarkButton"
                ) {
                    showBookmarks = true
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var pageInfoChip: some View {
        HStack(spacing: 6) {
            Text(currentSurahName)
                .font(.caption.weight(.medium))
                .foregroundStyle(theme.secondaryTextColor)
            Text("\(currentPage)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(theme.textColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .adaptiveGlass(
            in: Capsule(),
            tint: theme == .sepia ? Color.brown.opacity(0.15) : theme == .light ? Color.white.opacity(0.08) : nil,
            fallbackFill: toolbarChipFill,
            fallbackStroke: toolbarStroke
        )
        .allowsHitTesting(false)
        .accessibilityIdentifier("pageInfo")
    }

    @ViewBuilder
    private func toolbarCluster<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 10) {
                    content()
                }
                .padding(.horizontal, 6)
            }
        } else {
            HStack(spacing: 10) {
                content()
            }
        }
    }

    private var toolbarTint: Color? {
        switch theme {
        case .light:
            return .white.opacity(0.08)
        case .dark:
            return .gray.opacity(0.12)
        case .sepia:
            return .brown.opacity(0.16)
        case .amoled:
            return .white.opacity(0.05)
        }
    }

    private var toolbarStroke: Color {
        switch theme {
        case .light:
            return .black.opacity(0.06)
        case .dark:
            return .white.opacity(0.07)
        case .sepia:
            return Color(red: 0.54, green: 0.44, blue: 0.33).opacity(0.16)
        case .amoled:
            return .white.opacity(0.05)
        }
    }

    private func toolbarButton(
        systemName: String,
        tint: Color? = nil,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(tint ?? theme.secondaryTextColor)
        }
        .buttonStyle(
            AdaptiveGlassCircleButtonStyle(
                tint: tint ?? toolbarTint,
                fallbackFill: toolbarButtonFill,
                fallbackStroke: toolbarStroke
            )
        )
        .contentShape(Circle())
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var toolbarChipFill: AnyShapeStyle {
        switch theme {
        case .amoled:
            return AnyShapeStyle(Color.white.opacity(0.06))
        default:
            return AnyShapeStyle(.regularMaterial)
        }
    }

    private var toolbarButtonFill: AnyShapeStyle {
        switch theme {
        case .amoled:
            return AnyShapeStyle(Color.white.opacity(0.06))
        default:
            return AnyShapeStyle(.ultraThinMaterial)
        }
    }
}

// MARK: - Helper Types

private struct TafsirTarget: Identifiable {
    let id = UUID()
    let surah: Int
    let ayah: Int
}

private struct TranslationTarget: Identifiable {
    let id = UUID()
    let surah: Int
    let ayah: Int
}

private struct SurahInfoTarget: Identifiable {
    let id = UUID()
    let surah: Int
}
