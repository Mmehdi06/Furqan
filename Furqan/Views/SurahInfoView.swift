import SwiftUI

struct SurahInfoView: View {
    let surahNumber: Int
    @Environment(\.dismiss) private var dismiss
    @State private var name: String?
    @State private var shortText: String = ""
    @State private var sections: [(title: String, body: String)] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !sections.isEmpty || !shortText.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if !shortText.isEmpty {
                                Text(shortText)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .lineSpacing(4)

                                Divider()
                            }

                            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                                if !section.title.isEmpty {
                                    Text(section.title)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .padding(.top, 4)
                                }

                                Text(section.body)
                                    .font(.system(size: 15))
                                    .lineSpacing(6)
                                    .foregroundStyle(.primary.opacity(0.85))
                            }
                        }
                        .padding(20)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No information available")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(name ?? "Surah Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            Task.detached {
                let service = TafsirService.shared
                let info = service.surahInfo(forSurah: surahNumber)
                let rawHTML = service.surahInfoHTML(forSurah: surahNumber)
                let parsed = rawHTML.map { service.parseSections(from: $0) } ?? []
                await MainActor.run {
                    name = info?.name
                    shortText = info?.shortText ?? ""
                    sections = parsed
                    isLoading = false
                }
            }
        }
    }
}
