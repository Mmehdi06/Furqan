import SwiftUI

// MARK: - Translation Language

enum TranslationLanguage: String, CaseIterable, Identifiable {
    case french = "fr"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .french:  return "Français"
        case .english: return "English"
        }
    }

    var subtitle: String {
        switch self {
        case .french:  return "Muhammad Hamidullah"
        case .english: return "Sahih International"
        }
    }

    var icon: String {
        switch self {
        case .french:  return "🇫🇷"
        case .english: return "🇬🇧"
        }
    }

    var dbName: String {
        switch self {
        case .french:  return "translation-fr"
        case .english: return "translation-en"
        }
    }
}

// MARK: - Translation Manager

final class TranslationManager: ObservableObject {
    static let shared = TranslationManager()

    @Published var current: TranslationLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "translation_language")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "translation_language") ?? "fr"
        current = TranslationLanguage(rawValue: saved) ?? .french
    }
}

