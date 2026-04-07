import SwiftUI

struct SettingsView: View {
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var translationManager: TranslationManager
    @ObservedObject var statsManager = ReadingStatsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showStats = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    readingStatsSection
                    translationSection
                    themeSection
                }
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(themeManager.current.pageBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(themeManager.current.colorScheme)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showStats) {
            ReadingStatsView(statsManager: statsManager)
                .presentationDetents([.large])
        }
        .accessibilityIdentifier("settingsView")
    }

    // MARK: - Reading Stats Section

    private var readingStatsSection: some View {
        Button {
            showStats = true
        } label: {
            AdaptiveGlassCard(
                tint: sectionTint,
                cornerRadius: 30,
                fallbackFill: AnyShapeStyle(.thinMaterial),
                fallbackStroke: strokeColor
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("Reading Progress", systemImage: "chart.bar.fill")
                            .font(.headline)
                            .foregroundStyle(themeManager.current.textColor)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(themeManager.current.tertiaryTextColor)
                    }

                    HStack(spacing: 14) {
                        miniStat(
                            icon: "flame.fill",
                            iconColor: .orange,
                            value: "\(statsManager.currentStreak)",
                            label: "Streak"
                        )
                        miniStat(
                            icon: "book.fill",
                            iconColor: .green,
                            value: "\(statsManager.todayPages.count)",
                            label: "Today"
                        )
                        miniStat(
                            icon: "clock.fill",
                            iconColor: .blue,
                            value: statsManager.todayReadingTimeFormatted,
                            label: "Time"
                        )
                        miniStat(
                            icon: "checkmark.circle.fill",
                            iconColor: .purple,
                            value: String(format: "%.0f%%", statsManager.completionPercentage),
                            label: "Done"
                        )
                    }

                    // Mini progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.current.textColor.opacity(0.08))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: max(0, geo.size.width * CGFloat(statsManager.completionPercentage / 100.0)),
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(statsManager.totalPagesRead) / 604 pages")
                            .font(.caption)
                            .foregroundStyle(themeManager.current.secondaryTextColor)
                        Spacer()
                        Text("View details")
                            .font(.caption)
                            .foregroundStyle(themeManager.current.secondaryTextColor)
                    }
                }
                .padding(20)
            }
            .padding(.horizontal, 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func miniStat(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager.current.textColor)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(themeManager.current.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Translation Section

    private var translationSection: some View {
        AdaptiveGlassCard(
            tint: sectionTint,
            cornerRadius: 30,
            fallbackFill: AnyShapeStyle(.thinMaterial),
            fallbackStroke: strokeColor
        ) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Translation", systemImage: "globe")
                        .font(.headline)
                        .foregroundStyle(themeManager.current.textColor)
                    Text("Choose the language for ayah translations.")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.current.secondaryTextColor)
                }

                VStack(spacing: 10) {
                    ForEach(TranslationLanguage.allCases) { language in
                        translationRow(language)
                    }
                }
            }
            .padding(20)
        }
        .padding(.horizontal, 24)
    }

    private func translationRow(_ language: TranslationLanguage) -> some View {
        let isSelected = translationManager.current == language
        let theme = themeManager.current

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                translationManager.current = language
                TafsirService.shared.loadTranslationDB(for: language)
            }
        } label: {
            HStack(spacing: 14) {
                Text(language.icon)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textColor)
                    Text(language.subtitle)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? theme.textColor : theme.secondaryTextColor.opacity(0.4))
            }
            .padding(14)
            .adaptiveGlass(
                in: RoundedRectangle(cornerRadius: 18, style: .continuous),
                tint: isSelected ? selectedTint : nil,
                fallbackFill: AnyShapeStyle(theme.pageBackground.opacity(isSelected ? 0.96 : 0.88)),
                fallbackStroke: isSelected ? theme.textColor.opacity(0.18) : strokeColor
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        AdaptiveGlassCard(
            tint: sectionTint,
            cornerRadius: 30,
            fallbackFill: AnyShapeStyle(.thinMaterial),
            fallbackStroke: strokeColor
        ) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Reading Theme", systemImage: themeManager.current.icon)
                        .font(.headline)
                        .foregroundStyle(themeManager.current.textColor)
                    Text("Adjust the page surface and supporting chrome.")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.current.secondaryTextColor)
                }

                themePreview

                LazyVGrid(columns: gridColumns, spacing: 14) {
                    ForEach(ReadingTheme.allCases) { theme in
                        themeButton(theme)
                    }
                }
            }
            .padding(20)
        }
        .padding(.horizontal, 24)
        .id("theme-options-\(themeManager.current.rawValue)")
    }

    private var themePreview: some View {
        let theme = themeManager.current
        return VStack(alignment: .trailing, spacing: 10) {
            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 22))
                .foregroundStyle(theme.textColor)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text("ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ")
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(theme.textColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(18)
        .adaptiveGlass(
            in: RoundedRectangle(cornerRadius: 20, style: .continuous),
            tint: previewTint(for: theme),
            fallbackFill: AnyShapeStyle(theme.pageBackground.opacity(theme == .light ? 0.88 : 0.94)),
            fallbackStroke: strokeColor
        )
        .id("theme-preview-\(theme.rawValue)")
    }

    // MARK: - Theme Button

    private func themeButton(_ theme: ReadingTheme) -> some View {
        let isSelected = themeManager.current == theme

        return Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                themeManager.current = theme
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Circle()
                        .fill(theme.pageBackground)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: theme.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(theme.textColor)
                        )
                        .adaptiveGlass(
                            in: Circle(),
                            tint: isSelected ? previewTint(for: theme) : nil,
                            fallbackFill: AnyShapeStyle(theme.pageBackground.opacity(0.92)),
                            fallbackStroke: strokeColor
                        )

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? theme.textColor : theme.secondaryTextColor.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? theme.textColor : themeManager.current.textColor)
                    Text(themeHeadline(for: theme))
                        .font(.caption2)
                        .foregroundStyle(isSelected ? theme.secondaryTextColor : themeManager.current.secondaryTextColor)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .adaptiveGlass(
                in: RoundedRectangle(cornerRadius: 20, style: .continuous),
                tint: isSelected ? previewTint(for: theme) : nil,
                fallbackFill: AnyShapeStyle(theme.pageBackground.opacity(isSelected ? 0.96 : 0.88)),
                fallbackStroke: isSelected ? theme.textColor.opacity(0.18) : strokeColor
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .scaleEffect(isSelected ? 1 : 0.985)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ]
    }

    private func themeHeadline(for theme: ReadingTheme) -> String {
        switch theme {
        case .light:  return "Bright and airy"
        case .dark:   return "Dim and balanced"
        case .sepia:  return "Warm and paper-like"
        case .amoled: return "Pure black and focused"
        }
    }

    private var sectionTint: Color? {
        themeManager.current == .sepia ? Color.brown.opacity(0.18) : nil
    }

    private var selectedTint: Color? {
        previewTint(for: themeManager.current)
    }

    private func previewTint(for theme: ReadingTheme) -> Color? {
        switch theme {
        case .light:  return .white.opacity(0.08)
        case .dark:   return .gray.opacity(0.12)
        case .sepia:  return .brown.opacity(0.18)
        case .amoled: return .white.opacity(0.06)
        }
    }

    private var strokeColor: Color {
        switch themeManager.current {
        case .light:  return .black.opacity(0.06)
        case .dark:   return .white.opacity(0.06)
        case .sepia:  return Color(red: 0.55, green: 0.46, blue: 0.35).opacity(0.18)
        case .amoled: return .white.opacity(0.04)
        }
    }
}
