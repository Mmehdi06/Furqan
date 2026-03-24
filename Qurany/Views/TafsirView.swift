import SwiftUI

struct TafsirView: View {
    let surah: Int
    let ayah: Int
    @Environment(\.dismiss) private var dismiss
    @State private var tafsirText: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading tafsir...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let text = tafsirText, !text.isEmpty {
                    ScrollView {
                        Text(text)
                            .font(.system(size: 16))
                            .lineSpacing(6)
                            .padding(20)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No tafsir available for this ayah")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Tafsir Ibn Kathir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(surah):\(ayah)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            Task.detached {
                let text = TafsirService.shared.tafsir(forSurah: surah, ayah: ayah)
                await MainActor.run {
                    tafsirText = text
                    isLoading = false
                }
            }
        }
    }
}
