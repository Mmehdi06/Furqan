import SwiftUI

// MARK: - Theme Definition

enum ReadingTheme: String, CaseIterable, Identifiable, Codable {
    case light
    case dark
    case sepia
    case amoled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light:  return "Light"
        case .dark:   return "Dark"
        case .sepia:  return "Sepia"
        case .amoled: return "AMOLED"
        }
    }

    var icon: String {
        switch self {
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        case .sepia:  return "book.fill"
        case .amoled: return "circle.fill"
        }
    }

    // MARK: - Colors

    var pageBackground: Color {
        switch self {
        case .light:  return Color(.systemBackground)
        case .dark:   return Color(red: 0.15, green: 0.15, blue: 0.17)
        case .sepia:  return Color(red: 0.96, green: 0.93, blue: 0.87)
        case .amoled: return .black
        }
    }

    var textColor: Color {
        switch self {
        case .light:  return Color(.label)
        case .dark:   return Color(white: 0.90)
        case .sepia:  return Color(red: 0.26, green: 0.20, blue: 0.14)
        case .amoled: return Color(white: 0.92)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .light:  return Color(.secondaryLabel)
        case .dark:   return Color(white: 0.60)
        case .sepia:  return Color(red: 0.50, green: 0.42, blue: 0.33)
        case .amoled: return Color(white: 0.55)
        }
    }

    var tertiaryTextColor: Color {
        switch self {
        case .light:  return Color(.tertiaryLabel)
        case .dark:   return Color(white: 0.40)
        case .sepia:  return Color(red: 0.65, green: 0.58, blue: 0.50)
        case .amoled: return Color(white: 0.35)
        }
    }

    var uiTextColor: UIColor {
        switch self {
        case .light:  return .label
        case .dark:   return UIColor(white: 0.90, alpha: 1)
        case .sepia:  return UIColor(red: 0.26, green: 0.20, blue: 0.14, alpha: 1)
        case .amoled: return UIColor(white: 0.92, alpha: 1)
        }
    }

    var swiftHighlightColor: Color {
        Color(uiHighlightColor)
    }

    var uiHighlightColor: UIColor {
        switch self {
        case .light:  return UIColor(red: 0.85, green: 0.93, blue: 1.0, alpha: 1.0)
        case .dark:   return UIColor(red: 0.20, green: 0.30, blue: 0.45, alpha: 1.0)
        case .sepia:  return UIColor(red: 0.82, green: 0.75, blue: 0.62, alpha: 1.0)
        case .amoled: return UIColor(red: 0.15, green: 0.25, blue: 0.40, alpha: 1.0)
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light, .sepia: return .light
        case .dark, .amoled: return .dark
        }
    }

    /// Color fonts (QPC v4) have embedded black glyph color that ignores
    /// .foregroundColor. Dark themes need selective pixel inversion to turn
    /// black glyphs white while preserving tajweed colors.
    var needsSelectiveInvert: Bool {
        switch self {
        case .light, .sepia: return false
        case .dark, .amoled: return true
        }
    }
}

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var current: ReadingTheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "reading_theme")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "reading_theme") ?? "light"
        current = ReadingTheme(rawValue: saved) ?? .light
    }
}

// MARK: - Environment Key

private struct ReadingThemeKey: EnvironmentKey {
    static let defaultValue: ReadingTheme = .light
}

extension EnvironmentValues {
    var readingTheme: ReadingTheme {
        get { self[ReadingThemeKey.self] }
        set { self[ReadingThemeKey.self] = newValue }
    }
}
