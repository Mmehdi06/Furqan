import SwiftUI

struct SurahInfoView: View {
    let surahNumber: Int
    @Environment(\.dismiss) private var dismiss
    @State private var info: (name: String, text: String, shortText: String)?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let info = info {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Short summary
                            if !info.shortText.isEmpty {
                                Text(info.shortText)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .lineSpacing(4)
                            }

                            if !info.text.isEmpty {
                                Divider()

                                Text(info.text)
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
            .navigationTitle(info?.name ?? "Surah Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            Task.detached {
                let result = TafsirService.shared.surahInfo(forSurah: surahNumber)
                await MainActor.run {
                    info = result
                    isLoading = false
                }
            }
        }
    }
}
