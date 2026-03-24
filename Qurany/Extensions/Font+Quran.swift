import SwiftUI
import CoreText
import UIKit

final class QuranFontManager {
    static let shared = QuranFontManager()

    private var registeredPageFonts: [Int: String] = [:]
    private var staticFontsRegistered = false

    private init() {}

    // MARK: - Static Fonts (surah header)

    func registerStaticFonts() {
        guard !staticFontsRegistered else { return }
        staticFontsRegistered = true

        for fontFile in ["QCF_SurahHeader_COLOR-Regular", "UthmanicHafs_V22"] {
            if let url = Bundle.main.url(forResource: fontFile, withExtension: "ttf") {
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            }
        }
    }

    // MARK: - Per-Page QPC Fonts

    func fontName(forPage page: Int) -> String {
        if let cached = registeredPageFonts[page] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: "p\(page)", withExtension: "ttf", subdirectory: nil) else {
            return "Helvetica"
        }

        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)

        if let data = try? Data(contentsOf: url) as CFData,
           let provider = CGDataProvider(data: data),
           let cgFont = CGFont(provider),
           let psName = cgFont.postScriptName as String? {
            registeredPageFonts[page] = psName
            return psName
        }

        return "Helvetica"
    }

    func uiFont(forPage page: Int, size: CGFloat) -> UIFont {
        let name = fontName(forPage: page)
        return UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
    }
}

// MARK: - SwiftUI Font Extensions

extension Font {
    static func surahHeader(size: CGFloat) -> Font {
        .custom("QCF_SurahHeader_COLOR", size: size)
    }

    static func quranPage(_ page: Int, size: CGFloat) -> Font {
        let name = QuranFontManager.shared.fontName(forPage: page)
        return .custom(name, size: size)
    }
}
