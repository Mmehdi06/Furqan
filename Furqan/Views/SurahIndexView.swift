import SwiftUI

struct SurahIndexView: View {
    let surahs: [SurahInfo]
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredSurahs: [SurahInfo] {
        if searchText.isEmpty { return surahs }
        return surahs.filter {
            $0.nameArabic.contains(searchText) ||
            $0.nameSimple.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            "\($0.id)" == searchText
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredSurahs) { surah in
                Button {
                    onSelect(surah.startPage)
                    dismiss()
                } label: {
                    surahRow(surah)
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search surah...")
            .navigationTitle("Surahs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func surahRow(_ surah: SurahInfo) -> some View {
        HStack(spacing: 12) {
            // Surah number
            ZStack {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.tint.opacity(0.15))
                Text("\(surah.id)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 40)

            // Arabic name + English name
            VStack(alignment: .leading, spacing: 2) {
                Text(surah.nameSimple)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                Text("\(surah.revelationPlace.capitalized) · \(surah.versesCount) verses")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Arabic name
            Text(surah.nameArabic)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(.primary)
        }
    }
}
