import SwiftUI

struct AyahHighlight: Equatable {
    let surah: Int
    let ayah: Int
}

struct MushafPagerView: View {
    let pages: [QuranPage]
    let surahs: [SurahInfo]
    private let pendingDeepLink: Binding<AyahDeepLink?>?

    @State private var currentPage: Int
    @State private var showSurahIndex = false
    @State private var showBookmarks = false
    @State private var showSearch = false
    @State private var showReadingPlan = false
    @State private var showReadingPlanPrompt = false
    @State private var showBookmarkToast = false
    @State private var toastMessage = ""
    @State private var highlightedAyah: AyahHighlight?
    @State private var noteTarget: SavedAyah?
    @State private var viewedPagesForPlanPrompt: Set<Int> = []
    @State private var hasShownReadingPlanPromptThisSession = false
    @State private var didLeaveActiveScene = false
    @State private var planCompletionWorkItem: DispatchWorkItem?

    // Tafsir, Translation & Surah Info sheets
    @State private var tafsirTarget: (surah: Int, ayah: Int)?
    @State private var translationTarget: (surah: Int, ayah: Int)?
    @State private var surahInfoTarget: Int?
    @State private var showSettings = false

    @StateObject private var bookmarkManager = BookmarkManager.shared
    @StateObject private var translationManager = TranslationManager.shared
    @StateObject private var statsManager = ReadingStatsManager.shared
    @StateObject private var planManager = ReadingPlanManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.readingTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase

    private let lastPageKey = "quran_last_page"

    private var currentSurahName: String {
        surahs.last(where: { $0.startPage <= currentPage })?.nameSimple ?? ""
    }

    init(pages: [QuranPage], surahs: [SurahInfo], pendingDeepLink: Binding<AyahDeepLink?>? = nil) {
        self.pages = pages
        self.surahs = surahs
        self.pendingDeepLink = pendingDeepLink
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
                statsManager.recordPageView(newPage)
                recordViewedPageForPlanPrompt(newPage)
                schedulePlanCompletion(for: newPage)
            }
            .onAppear {
                statsManager.startSession()
                statsManager.recordPageView(currentPage)
                recordViewedPageForPlanPrompt(currentPage)
                schedulePlanCompletion(for: currentPage)
                applyPendingDeepLinkIfNeeded()
            }
            .onChange(of: pendingDeepLink?.wrappedValue) { _, _ in
                applyPendingDeepLinkIfNeeded()
            }
            .onDisappear {
                statsManager.endSession()
                planCompletionWorkItem?.cancel()
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
        .sheet(isPresented: $showReadingPlan) {
            ReadingPlanView(planManager: planManager, initialStartPage: currentPage)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showReadingPlanPrompt) {
            ReadingPlanPromptView {
                planManager.dismissPrompt()
                showReadingPlanPrompt = false
                showReadingPlan = true
            } onDismiss: {
                planManager.dismissPrompt()
                showReadingPlanPrompt = false
            }
            .presentationDetents([.height(200)])
        }
        .sheet(item: $noteTarget) { savedAyah in
            SavedAyahNoteEditor(savedAyah: savedAyah, bookmarkManager: bookmarkManager)
                .presentationDetents([.medium, .large])
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
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

        case .saveAyah(let surah, let ayah, let page):
            let surahName = QuranDataService.shared.surahName(forPage: page)
            bookmarkManager.saveAyah(page: page, surahName: surahName, surah: surah, ayah: ayah)
            showToast("Saved \(surah):\(ayah)")

        case .removeSavedAyah(let surah, let ayah):
            bookmarkManager.removeSavedAyah(surah: surah, ayah: ayah)
            showToast("Removed saved ayah")

        case .editNote(let surah, let ayah, let page):
            let surahName = QuranDataService.shared.surahName(forPage: page)
            noteTarget = bookmarkManager.saveAyah(page: page, surahName: surahName, surah: surah, ayah: ayah)
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation { showBookmarkToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showBookmarkToast = false }
        }
    }

    private func recordViewedPageForPlanPrompt(_ page: Int) {
        guard !planManager.shouldSuppressPrompt, !hasShownReadingPlanPromptThisSession else { return }
        viewedPagesForPlanPrompt.insert(page)
        if viewedPagesForPlanPrompt.count >= 3 {
            hasShownReadingPlanPromptThisSession = true
            showReadingPlanPrompt = true
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            guard didLeaveActiveScene else { return }
            didLeaveActiveScene = false
            hasShownReadingPlanPromptThisSession = false
            viewedPagesForPlanPrompt = []
            recordViewedPageForPlanPrompt(currentPage)

        case .inactive, .background:
            didLeaveActiveScene = true

        @unknown default:
            break
        }
    }

    private func schedulePlanCompletion(for page: Int) {
        planCompletionWorkItem?.cancel()
        guard planManager.activePlan?.contains(page: page) == true else { return }

        let workItem = DispatchWorkItem { [page] in
            guard currentPage == page else { return }
            planManager.markPageCompleted(page)
        }
        planCompletionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    // MARK: - Ayah Highlight

    private func highlightAyah(surah: Int, ayah: Int) {
        highlightedAyah = AyahHighlight(surah: surah, ayah: ayah)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            highlightedAyah = nil
        }
    }

    private func applyPendingDeepLinkIfNeeded() {
        guard let pendingDeepLink else { return }
        guard let target = pendingDeepLink.wrappedValue else { return }
        guard let page = QuranSearchService.shared.pageNumber(forSurah: target.surah, ayah: target.ayah) else { return }

        currentPage = page
        highlightAyah(surah: target.surah, ayah: target.ayah)
        pendingDeepLink.wrappedValue = nil
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
                    systemName: "bookmark",
                    accessibilityIdentifier: "bookmarkButton"
                ) {
                    showBookmarks = true
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var pageInfoChip: some View {
        Button {
            if planManager.activePlan != nil {
                showReadingPlan = true
            }
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .center, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(currentSurahName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(theme.secondaryTextColor)
                        Text("\(currentPage)")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(theme.textColor)
                    }

                    if let plan = planManager.activePlan {
                        ProgressView(value: plan.completionPercentage, total: 100)
                            .progressViewStyle(.linear)
                            .tint(.green)
                            .frame(width: 74)
                            .scaleEffect(y: 0.55)
                    }
                }

                if planManager.activePlan != nil {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(theme.tertiaryTextColor)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .adaptiveGlass(
            in: Capsule(),
            tint: theme == .sepia ? Color.brown.opacity(0.15) : theme == .light ? Color.white.opacity(0.08) : nil,
            fallbackFill: toolbarChipFill,
            fallbackStroke: toolbarStroke
        )
        .buttonStyle(.plain)
        .disabled(planManager.activePlan == nil)
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
