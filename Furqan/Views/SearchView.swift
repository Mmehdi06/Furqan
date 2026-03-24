import SwiftUI

struct SearchView: View {
    let onSelect: (Int, Int, Int) -> Void  // (page, surah, ayah)
    @Environment(\.dismiss) private var dismiss

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
                // Search field
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("ابحث في القرآن...", text: $searchText)
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
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Content
                if isSearching {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if hasSearched && results.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No results found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                } else if !results.isEmpty {
                    resultCountHeader
                    resultsList
                } else if !searchHistory.isEmpty {
                    // Show search history when no active search
                    historyView
                } else {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("Search the Quran")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Enter Arabic text to find verses")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
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

    private var historyView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent searches")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    searchHistory = []
                    SearchHistoryManager.clear()
                } label: {
                    Text("Clear")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            List(searchHistory, id: \.self) { query in
                Button {
                    searchText = query
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)

                        Text(query)
                            .font(.system(size: 17, design: .serif))
                            .foregroundStyle(.primary)
                            .environment(\.layoutDirection, .rightToLeft)

                        Spacer()

                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Results Subviews

    private var resultCountHeader: some View {
        HStack {
            Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var resultsList: some View {
        List(results) { result in
            Button {
                saveToHistory(searchText)
                onSelect(result.pageNumber, result.surah, result.ayah)
                dismiss()
            } label: {
                resultRow(result)
            }
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        }
        .listStyle(.plain)
    }

    private func resultRow(_ result: SearchResult) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text("Page \(result.pageNumber)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text("\(result.surahName)")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundStyle(.primary)

                Text("(\(result.surah):\(result.ayah))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(result.verseText)
                .font(.system(size: 18, design: .serif))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
        }
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
                QuranSearchService.shared.search(query: trimmed)
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
