import SwiftUI

struct SurahIndexView: View {
    let surahs: [SurahInfo]
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.readingTheme) private var theme

    @State private var searchText = ""
    @State private var filterMode: FilterMode = .all

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case makkah = "Makkah"
        case madinah = "Madinah"
    }

    private var filteredSurahs: [SurahInfo] {
        var result = surahs

        if filterMode == .makkah {
            result = result.filter { $0.revelationPlace == "makkah" }
        } else if filterMode == .madinah {
            result = result.filter { $0.revelationPlace == "madinah" }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.nameArabic.contains(searchText) ||
                $0.nameSimple.localizedCaseInsensitiveContains(searchText) ||
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                "\($0.id)" == searchText
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                        .padding(.top, 12)

                    filterSection

                    resultSummary

                    LazyVStack(spacing: 14) {
                        ForEach(filteredSurahs) { surah in
                            Button {
                                onSelect(surah.startPage)
                                dismiss()
                            } label: {
                                surahCard(surah)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if filteredSurahs.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .background(theme.pageBackground.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Search surah")
            .navigationTitle("Surahs")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var headerCard: some View {
        AdaptiveGlassCard(
            tint: chromeTint,
            cornerRadius: 28,
            fallbackFill: cardFill,
            fallbackStroke: cardStroke
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Surah Index")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(theme.textColor)
                        Text("Jump quickly to any surah, then continue reading from its opening page.")
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryTextColor)
                    }

                    Spacer()

                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(theme.textColor)
                        .padding(11)
                        .adaptiveGlass(
                            in: Circle(),
                            tint: chromeTint,
                            fallbackFill: iconFill,
                            fallbackStroke: cardStroke
                        )
                }

                HStack(spacing: 10) {
                    statChip(title: "Total", value: "\(surahs.count)")
                    statChip(title: "Shown", value: "\(filteredSurahs.count)")
                    statChip(title: "Filter", value: filterMode.rawValue)
                }
            }
            .padding(20)
        }
    }

    private var filterSection: some View {
        AdaptiveGlassCard(
            tint: chromeTint,
            cornerRadius: 24,
            fallbackFill: cardFill,
            fallbackStroke: cardStroke
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Filter by revelation")
                    .font(.headline)
                    .foregroundStyle(theme.textColor)

                HStack(spacing: 10) {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        filterChip(mode)
                    }
                }
            }
            .padding(18)
        }
    }

    private var resultSummary: some View {
        HStack {
            Text(filteredSurahs.isEmpty ? "No matching surahs" : "\(filteredSurahs.count) surah\(filteredSurahs.count == 1 ? "" : "s")")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.secondaryTextColor)

            Spacer()

            if !searchText.isEmpty {
                Text("Search: \(searchText)")
                    .font(.caption)
                    .foregroundStyle(theme.tertiaryTextColor)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 4)
    }

    private func filterChip(_ mode: FilterMode) -> some View {
        let isSelected = filterMode == mode

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                filterMode = mode
            }
        } label: {
            Text(mode.rawValue)
                .font(.subheadline.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? theme.textColor : theme.secondaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .adaptiveGlass(
                    in: Capsule(),
                    tint: isSelected ? chromeTint : nil,
                    fallbackFill: isSelected ? selectedChipFill : chipFill,
                    fallbackStroke: cardStroke
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func surahCard(_ surah: SurahInfo) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                surahNumberBadge(surah.id)

                VStack(alignment: .leading, spacing: 3) {
                    Text(surah.nameSimple)
                        .font(.headline)
                        .foregroundStyle(theme.textColor)

                    Text(surah.name)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                HStack(alignment: .top, spacing: 10) {
                    Text(surah.nameArabic)
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .foregroundStyle(theme.textColor)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: true, vertical: false)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.tertiaryTextColor)
                        .padding(.top, 6)
                }
            }

            HStack(spacing: 8) {
                metadataChip(
                    icon: surah.revelationPlace == "makkah" ? "building.columns" : "building.2",
                    text: surah.revelationPlace == "makkah" ? "Makkah" : "Madinah"
                )

                metadataChip(
                    icon: "text.justify",
                    text: "\(surah.versesCount) verses"
                )

                metadataChip(
                    icon: "book.pages",
                    text: "Page \(surah.startPage)"
                )

                Spacer(minLength: 0)
            }
            .padding(.leading, 70)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlass(
            in: RoundedRectangle(cornerRadius: 26, style: .continuous),
            tint: chromeTint,
            fallbackFill: cardFill,
            fallbackStroke: cardStroke
        )
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func surahNumberBadge(_ number: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.textColor.opacity(theme == .light || theme == .sepia ? 0.05 : 0.10))
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(cardStroke, lineWidth: 1)
                )

            VStack(spacing: 2) {
                Text("\(number)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textColor)
                Text("No.")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(theme.tertiaryTextColor)
            }
        }
    }

    private func metadataChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .foregroundStyle(theme.secondaryTextColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(theme.textColor.opacity(theme == .light || theme == .sepia ? 0.05 : 0.10), in: Capsule())
        .fixedSize(horizontal: true, vertical: true)
    }

    private func statChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(theme.tertiaryTextColor)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.textColor.opacity(theme == .light || theme == .sepia ? 0.05 : 0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(theme.secondaryTextColor)

            VStack(spacing: 6) {
                Text("No surah found")
                    .font(.headline)
                    .foregroundStyle(theme.textColor)
                Text("Try a different surah name, number, or revelation filter.")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .adaptiveGlass(
            in: RoundedRectangle(cornerRadius: 28, style: .continuous),
            tint: chromeTint,
            fallbackFill: cardFill,
            fallbackStroke: cardStroke
        )
    }

    private var chromeTint: Color? {
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

    private var iconFill: AnyShapeStyle {
        switch theme {
        case .amoled:
            return AnyShapeStyle(Color.white.opacity(0.06))
        default:
            return AnyShapeStyle(.ultraThinMaterial)
        }
    }

    private var chipFill: AnyShapeStyle {
        switch theme {
        case .amoled:
            return AnyShapeStyle(Color.white.opacity(0.04))
        case .sepia:
            return AnyShapeStyle(theme.pageBackground.opacity(0.92))
        default:
            return AnyShapeStyle(.ultraThinMaterial)
        }
    }

    private var selectedChipFill: AnyShapeStyle {
        switch theme {
        case .amoled:
            return AnyShapeStyle(Color.white.opacity(0.08))
        case .sepia:
            return AnyShapeStyle(theme.pageBackground.opacity(0.98))
        default:
            return AnyShapeStyle(.regularMaterial)
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
