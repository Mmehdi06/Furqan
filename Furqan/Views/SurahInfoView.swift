import SwiftUI

struct SurahInfoView: View {
    let surahNumber: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.readingTheme) private var theme
    @State private var name: String?
    @State private var shortText: String = ""
    @State private var sections: [(title: String, body: String)] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    centeredCard(
                        icon: "info.circle",
                        title: "Loading surah info",
                        message: "Preparing background and context for this surah."
                    ) {
                        ProgressView()
                            .tint(theme.textColor)
                    }
                } else if !sections.isEmpty || !shortText.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            headerChip

                            if !shortText.isEmpty {
                                AdaptiveGlassCard(
                                    tint: themeTint,
                                    cornerRadius: 24,
                                    fallbackFill: cardFill,
                                    fallbackStroke: cardStroke
                                ) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Overview")
                                            .font(.headline)
                                            .foregroundStyle(theme.textColor)
                                        Text(shortText)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(theme.textColor)
                                            .lineSpacing(5)
                                    }
                                    .padding(20)
                                }
                            }

                            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                                AdaptiveGlassCard(
                                    tint: nil,
                                    cornerRadius: 24,
                                    fallbackFill: cardFill,
                                    fallbackStroke: cardStroke
                                ) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        if !section.title.isEmpty {
                                            Text(section.title)
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(theme.textColor)
                                        }

                                        Text(section.body)
                                            .font(.system(size: 15))
                                            .lineSpacing(6)
                                            .foregroundStyle(theme.secondaryTextColor)
                                    }
                                    .padding(20)
                                }
                            }
                        }
                        .padding(20)
                    }
                } else {
                    centeredCard(
                        icon: "info.circle",
                        title: "No information available",
                        message: "This surah does not currently have a background summary."
                    )
                }
            }
            .background(theme.pageBackground.ignoresSafeArea())
            .navigationTitle(name ?? "Surah Info")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
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

    private var headerChip: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14, weight: .semibold))
            Text("Surah \(surahNumber)")
                .font(.caption.weight(.semibold))
        }
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
