import SwiftUI

struct TranslationView: View {
    let surah: Int
    let ayah: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.readingTheme) private var theme
    @State private var translationText: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    centeredCard(
                        icon: "globe",
                        title: "Loading translation",
                        message: "Fetching the translation for this ayah."
                    ) {
                        ProgressView()
                            .tint(theme.textColor)
                    }
                } else if let text = translationText {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            verseChip

                            AdaptiveGlassCard(
                                tint: themeTint,
                                cornerRadius: 26,
                                fallbackFill: cardFill,
                                fallbackStroke: cardStroke
                            ) {
                                Text(text)
                                    .font(.body)
                                    .lineSpacing(6)
                                    .foregroundStyle(theme.textColor)
                                    .padding(20)
                            }
                        }
                        .padding(20)
                    }
                } else {
                    centeredCard(
                        icon: "globe",
                        title: "No translation available",
                        message: "This ayah does not currently have a translation available."
                    )
                }
            }
            .background(theme.pageBackground.ignoresSafeArea())
            .navigationTitle("Translation")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                let s = surah, a = ayah
                let text = await Task.detached {
                    TafsirService.shared.translation(forSurah: s, ayah: a)
                }.value
                translationText = text
                isLoading = false
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
                tint: themeTint,
                fallbackFill: cardFill,
                fallbackStroke: cardStroke
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
            tint: themeTint,
            fallbackFill: cardFill,
            fallbackStroke: cardStroke
        )
        .padding(20)
    }

    private var themeTint: Color? {
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
