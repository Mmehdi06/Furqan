import SwiftUI

struct TafsirView: View {
    let surah: Int
    let ayah: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.readingTheme) private var theme
    @State private var tafsirText: String?
    @State private var isLoading = true
    private var palette: NativeGlassPalette { theme.nativeGlassPalette }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    centeredCard(
                        icon: "book.closed",
                        title: "Loading tafsir",
                        message: "Gathering commentary for this ayah."
                    ) {
                        ProgressView()
                            .tint(theme.textColor)
                    }
                } else if let text = tafsirText, !text.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            verseChip

                            NativeGlassSectionCard(cornerRadius: 26, tint: palette.sectionTint, elevated: true) {
                                Text(text)
                                    .font(.system(size: 16))
                                    .lineSpacing(6)
                                    .foregroundStyle(theme.textColor)
                                    .padding(20)
                            }
                        }
                        .padding(20)
                    }
                } else {
                    centeredCard(
                        icon: "book.closed",
                        title: "No tafsir available",
                        message: "This ayah does not currently have commentary in the selected source."
                    )
                }
            }
            .background(theme.pageBackground.ignoresSafeArea())
            .navigationTitle("Tafsir Ibn Kathir")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EmptyView()
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

    private var verseChip: some View {
        Text("\(surah):\(ayah)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.secondaryTextColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .adaptiveGlass(
            in: Capsule(),
            tint: palette.chromeTint,
            fallbackFill: palette.elevatedFill,
            fallbackStroke: palette.stroke
        )
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func centeredCard(
        icon: String,
        title: String,
        message: String,
        @ViewBuilder accessory: () -> some View = { EmptyView() }
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .medium))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .adaptiveGlass(
            in: RoundedRectangle(cornerRadius: 28, style: .continuous),
            tint: palette.sectionTint,
            fallbackFill: palette.cardFill,
            fallbackStroke: palette.stroke
        )
        .padding(20)
    }

    private var cardFill: AnyShapeStyle {
        palette.cardFill
    }

    private var cardStroke: Color {
        palette.stroke
    }
}
