import SwiftUI
import CoreText

enum QuranFonts {
    static var registered = false

    static func registerAll() {
        guard !registered else { return }
        registered = true

        let fontFiles = [
            "quran-common",
            "QCF_SurahHeader_COLOR-Regular",
            "surah-name-v2"
        ]

        for fontFile in fontFiles {
            if let url = Bundle.main.url(forResource: fontFile, withExtension: "ttf") {
                var error: Unmanaged<CFError>?
                if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    print("Failed to register font \(fontFile): \(String(describing: error?.takeRetainedValue()))")
                }
            } else {
                print("Font file not found: \(fontFile).ttf")
            }
        }
    }
}

extension Font {
    static func quranText(size: CGFloat) -> Font {
        .custom("quran-common", size: size)
    }

    static func surahHeader(size: CGFloat) -> Font {
        .custom("QCF_SurahHeader_COLOR", size: size)
    }

    static func surahName(size: CGFloat) -> Font {
        .custom("surah-name-v2", size: size)
    }
}
