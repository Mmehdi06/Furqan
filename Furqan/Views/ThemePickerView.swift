import SwiftUI

struct ThemePickerView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    themePreview
                        .padding(.top, 16)

                    AdaptiveGlassCard(
                        tint: themeManager.current == .sepia ? Color.brown.opacity(0.18) : nil,
                        cornerRadius: 30,
                        fallbackFill: AnyShapeStyle(.thinMaterial),
                        fallbackStroke: pickerStrokeColor(for: themeManager.current)
                    ) {
                        VStack(alignment: .leading, spacing: 18) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choose a reading atmosphere")
                                    .font(.headline)
                                    .foregroundStyle(themeManager.current.textColor)
                                Text("Each theme adjusts the page surface and supporting chrome without changing the reading layout.")
                                    .font(.subheadline)
                                    .foregroundStyle(themeManager.current.secondaryTextColor)
                            }

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
                .padding(.bottom, 28)
            }
            .background(themeManager.current.pageBackground.ignoresSafeArea())
            .navigationTitle("Reading Theme")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(themeManager.current.colorScheme)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("themePickerView")
    }

    // MARK: - Preview

    private var themePreview: some View {
        let theme = themeManager.current
        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(theme.textColor)
                    Text(themeHeadline(for: theme))
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()

                Image(systemName: theme.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(theme.textColor)
                    .padding(10)
                    .adaptiveGlass(
                        in: Circle(),
                        tint: previewTint(for: theme),
                        fallbackFill: AnyShapeStyle(theme.pageBackground.opacity(0.92)),
                        fallbackStroke: pickerStrokeColor(for: theme)
                    )
            }

            VStack(alignment: .trailing, spacing: 12) {
                Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                    .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 24))
                    .foregroundStyle(theme.textColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundStyle(theme.textColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            HStack {
                Text("Live preview")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.secondaryTextColor)
                Spacer()
                Text(theme.colorScheme == .dark ? "Dark appearance" : "Light appearance")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.tertiaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.textColor.opacity(theme == .light || theme == .sepia ? 0.06 : 0.12), in: Capsule())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .adaptiveGlass(
            in: RoundedRectangle(cornerRadius: 24, style: .continuous),
            tint: previewTint(for: theme),
            fallbackFill: AnyShapeStyle(theme.pageBackground.opacity(theme == .light ? 0.88 : 0.94)),
            fallbackStroke: pickerStrokeColor(for: theme)
        )
        .padding(.horizontal, 24)
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
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Circle()
                        .fill(theme.pageBackground)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: theme.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(theme.textColor)
                        )
                        .adaptiveGlass(
                            in: Circle(),
                            tint: isSelected ? previewTint(for: theme) : nil,
                            fallbackFill: AnyShapeStyle(theme.pageBackground.opacity(0.92)),
                            fallbackStroke: pickerStrokeColor(for: theme)
                        )

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? theme.textColor : theme.secondaryTextColor.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? theme.textColor : themeManager.current.textColor)
                    Text(themeHeadline(for: theme))
                        .font(.caption)
                        .foregroundStyle(isSelected ? theme.secondaryTextColor : themeManager.current.secondaryTextColor)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
            .adaptiveGlass(
                in: RoundedRectangle(cornerRadius: 22, style: .continuous),
                tint: isSelected ? previewTint(for: theme) : nil,
                fallbackFill: AnyShapeStyle(theme.pageBackground.opacity(isSelected ? 0.96 : 0.88)),
                fallbackStroke: isSelected ? theme.textColor.opacity(0.18) : pickerStrokeColor(for: themeManager.current)
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .scaleEffect(isSelected ? 1 : 0.985)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ]
    }

    private func themeHeadline(for theme: ReadingTheme) -> String {
        switch theme {
        case .light:
            return "Bright and airy"
        case .dark:
            return "Dim and balanced"
        case .sepia:
            return "Warm and paper-like"
        case .amoled:
            return "Pure black and focused"
        }
    }

    private func previewTint(for theme: ReadingTheme) -> Color? {
        switch theme {
        case .light:
            return .white.opacity(0.08)
        case .dark:
            return .gray.opacity(0.12)
        case .sepia:
            return .brown.opacity(0.18)
        case .amoled:
            return .white.opacity(0.06)
        }
    }

    private func pickerStrokeColor(for theme: ReadingTheme) -> Color {
        switch theme {
        case .light:
            return .black.opacity(0.06)
        case .dark:
            return .white.opacity(0.06)
        case .sepia:
            return Color(red: 0.55, green: 0.46, blue: 0.35).opacity(0.18)
        case .amoled:
            return .white.opacity(0.04)
        }
    }
}
