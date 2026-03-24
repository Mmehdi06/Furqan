import SwiftUI

struct TranslationView: View {
    let surah: Int
    let ayah: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(surah):\(ayah)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    if let text = TafsirService.shared.translation(forSurah: surah, ayah: ayah) {
                        Text(text)
                            .font(.body)
                            .lineSpacing(6)
                    } else {
                        Text("No translation available for this ayah.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Translation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
