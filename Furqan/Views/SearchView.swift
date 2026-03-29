import SwiftUI

struct SearchView: View {
    let onSelect: (Int, Int, Int) -> Void  // (page, surah, ayah)
    @Environment(\.dismiss) private var dismiss
    @Environment(\.readingTheme) private var theme

    @State private var searchText = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchTask: Task<Void, Never>?
    @State private var searchHistory: [String] = SearchHistoryManager.load()

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchHeader

                contentView
            }
            .background(theme.pageBackground.ignoresSafeArea())
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: searchText) { _, newValue in
                performDebouncedSearch(newValue)
            }
        }
        .onAppear {
            isFieldFocused = true
        }
    }

    // MARK: - History View

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Find verses by Arabic text or jump directly with a surah and ayah reference.")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.secondaryTextColor)

                TextField("ابحث في القرآن...", text: $searchText)
                    .accessibilityIdentifier("searchField")
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFieldFocused)
                    .environment(\.layoutDirection, .rightToLeft)
                    .environment(\.locale, Locale(identifier: "ar"))
                    .submitLabel(.search)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        results = []
                        hasSearched = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .adaptiveGlass(
                in: RoundedRectangle(cornerRadius: 18, style: .continuous),
                tint: searchChromeTint,
                fallbackFill: searchFieldFill,
                fallbackStroke: cardStroke
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var contentView: some View {
        if isSearching {
            stateCard(
                icon: "magnifyingglass.circle",
                title: "Searching...",
                message: "Looking through the Quran for matches."
            ) {
                ProgressView()
                    .tint(theme.textColor)
            }
        } else if hasSearched && results.isEmpty {
            stateCard(
                icon: "text.magnifyingglass",
                title: "No results found",
                message: "Try a different Arabic phrase or a surah:ayah reference."
            )
        } else if !results.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    resultCountHeader

                    LazyVStack(spacing: 12) {
                        ForEach(results) { result in
                            Button {
                                saveToHistory(searchText)
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now()) {
                                    onSelect(result.pageNumber, result.surah, result.ayah)
                                }
                            } label: {
                                resultRow(result)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .accessibilityIdentifier("searchResultsList")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        } else if !searchHistory.isEmpty {
            historyView
        } else {
            stateCard(
                icon: "book.pages",
                title: "Search the Quran",
                message: "Enter Arabic text to find verses and jump straight into the reader."
            )
        }
    }

    private var historyView: some View {
        ScrollView {
            VStack(spacing: 12) {
            HStack {
                Text("Recent searches")
                        .font(.headline)
                        .foregroundStyle(theme.textColor)
                Spacer()
                Button {
                    searchHistory = []
                    SearchHistoryManager.clear()
                } label: {
                    Text("Clear")
                            .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                }
            }
                .padding(.top, 4)

                LazyVStack(spacing: 12) {
                    ForEach(searchHistory, id: \.self) { query in
                        Button {
                            searchText = query
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(theme.secondaryTextColor)

                                Text(query)
                                    .font(.system(size: 18, weight: .medium, design: .serif))
                                    .foregroundStyle(theme.textColor)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .environment(\.layoutDirection, .rightToLeft)

                                Image(systemName: "arrow.up.left")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(theme.tertiaryTextColor)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .adaptiveGlass(
                                in: RoundedRectangle(cornerRadius: 22, style: .continuous),
                                tint: searchChromeTint,
                                fallbackFill: cardFill,
                                fallbackStroke: cardStroke
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Results Subviews

    private var resultCountHeader: some View {
        HStack {
            Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.secondaryTextColor)
            Spacer()
            Text("Tap a verse to open it")
                .font(.caption)
                .foregroundStyle(theme.tertiaryTextColor)
        }
    }

    private func resultRow(_ result: SearchResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Page \(result.pageNumber)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.tertiaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.textColor.opacity(theme == .light || theme == .sepia ? 0.06 : 0.12), in: Capsule())

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(result.surahName)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(theme.textColor)

                    Text("\(result.surah):\(result.ayah)")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }

            Text(result.verseText)
                .font(.system(size: 19, weight: .medium, design: .serif))
                .foregroundStyle(theme.textColor)
                .multilineTextAlignment(.trailing)
                .lineSpacing(4)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlass(
            in: RoundedRectangle(cornerRadius: 22, style: .continuous),
            tint: searchChromeTint,
            fallbackFill: cardFill,
            fallbackStroke: cardStroke
        )
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Search

    private func performDebouncedSearch(_ query: String) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            results = []
            hasSearched = false
            isSearching = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run { isSearching = true }

            let searchResults = await Task.detached {
                // Check for surah:ayah reference (e.g. "23:65")
                if let refResults = QuranSearchService.shared.lookupByReference(trimmed) {
                    return refResults
                }
                return QuranSearchService.shared.search(query: trimmed)
            }.value

            guard !Task.isCancelled else { return }

            await MainActor.run {
                results = searchResults
                hasSearched = true
                isSearching = false
            }
        }
    }

    // MARK: - History

    private func saveToHistory(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Remove duplicate if exists, add to front
        searchHistory.removeAll { $0 == trimmed }
        searchHistory.insert(trimmed, at: 0)

        // Keep max 20
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }

        SearchHistoryManager.save(searchHistory)
    }

    @ViewBuilder
    private func stateCard(
        icon: String,
        title: String,
        message: String,
        @ViewBuilder accessory: () -> some View = { EmptyView() }
    ) -> some View {
        Spacer()
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(theme.secondaryTextColor)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(theme.textColor)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            accessory()
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .adaptiveGlass(
            in: RoundedRectangle(cornerRadius: 28, style: .continuous),
            tint: searchChromeTint,
            fallbackFill: cardFill,
            fallbackStroke: cardStroke
        )
        .padding(.horizontal, 20)
        Spacer()
    }

    private var searchChromeTint: Color? {
        switch theme {
        case .light:
            return .white.opacity(0.10)
        case .dark:
            return .gray.opacity(0.12)
        case .sepia:
            return .brown.opacity(0.16)
        case .amoled:
            return .white.opacity(0.05)
        }
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

    private var searchFieldFill: AnyShapeStyle {
        switch theme {
        case .light:
            return AnyShapeStyle(Color(.systemGray6))
        case .sepia:
            return AnyShapeStyle(theme.pageBackground.opacity(0.92))
        case .amoled:
            return AnyShapeStyle(Color.white.opacity(0.05))
        case .dark:
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

// MARK: - Search History Persistence

enum SearchHistoryManager {
    private static let key = "quran_search_history"

    static func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    static func save(_ history: [String]) {
        UserDefaults.standard.set(history, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
