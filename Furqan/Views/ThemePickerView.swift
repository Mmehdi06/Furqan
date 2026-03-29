import SwiftUI

struct ThemePickerView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                themePreview
                    .padding(.top, 16)

                // Theme options
                AdaptiveGlassCard(
                    tint: themeManager.current == .sepia ? Color.brown.opacity(0.18) : nil,
                    cornerRadius: 28,
                    fallbackFill: AnyShapeStyle(.thinMaterial),
                    fallbackStroke: pickerStrokeColor(for: themeManager.current)
                ) {
                    HStack(spacing: 16) {
                        ForEach(ReadingTheme.allCases) { theme in
                            themeButton(theme)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
                .padding(.horizontal, 24)
                .id("theme-options-\(themeManager.current.rawValue)")

                Spacer()
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
        return VStack(spacing: 12) {
            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 22))
                .foregroundStyle(theme.textColor)

            Text("ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ")
                .font(.system(size: 20, design: .serif))
                .foregroundStyle(theme.textColor)

            Text("Preview")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
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
            VStack(spacing: 8) {
                Circle()
                    .fill(theme.pageBackground)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .overlay(
                        Image(systemName: theme.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(theme.textColor)
                    )
                    .adaptiveGlass(
                        in: Circle(),
                        tint: isSelected ? previewTint(for: theme) : nil,
                        fallbackFill: AnyShapeStyle(theme.pageBackground.opacity(0.92)),
                        fallbackStroke: pickerStrokeColor(for: theme)
                    )

                Text(theme.displayName)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isSelected ? themeManager.current.textColor : themeManager.current.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
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
