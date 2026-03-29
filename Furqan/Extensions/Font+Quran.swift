import SwiftUI
import CoreText
import UIKit

// Wrapper for CGFont to use with NSCache (requires reference types)
private class CGFontWrapper {
    let font: CGFont
    init(_ font: CGFont) { self.font = font }
}

final class QuranFontManager: @unchecked Sendable {
    static let shared = QuranFontManager()

    private let lock = NSLock()
    private var registeredPageFonts: [Int: String] = [:]
    private let cachedDarkCGFonts: NSCache<NSNumber, CGFontWrapper> = {
        let cache = NSCache<NSNumber, CGFontWrapper>()
        cache.countLimit = 30 // Keep ~30 pages in memory, evict the rest
        return cache
    }()
    private var darkSurahHeaderCGFont: CGFont?
    private var staticFontsRegistered = false
    private var darkFontsReady = false

    private let darkFontDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DarkFonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private init() {}

    // MARK: - Static Fonts (surah header, basmallah, logo)

    func registerStaticFonts() {
        guard !staticFontsRegistered else { return }
        staticFontsRegistered = true

        for fontFile in ["QCF_SurahHeader_COLOR-Regular", "UthmanicHafs_V22", "Oi-Regular"] {
            if let url = Bundle.main.url(forResource: fontFile, withExtension: "ttf") {
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            }
        }
    }

    // MARK: - Per-Page QPC Fonts (light mode)

    func fontName(forPage page: Int) -> String {
        lock.lock()
        if let cached = registeredPageFonts[page] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        guard let url = Bundle.main.url(forResource: "p\(page)", withExtension: "ttf", subdirectory: nil) else {
            return "Helvetica"
        }

        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)

        if let data = try? Data(contentsOf: url) as CFData,
           let provider = CGDataProvider(data: data),
           let cgFont = CGFont(provider),
           let psName = cgFont.postScriptName as String? {
            lock.lock()
            registeredPageFonts[page] = psName
            lock.unlock()
            return psName
        }

        return "Helvetica"
    }

    // MARK: - Per-Page QPC Fonts (dark mode — CPAL modified, loaded via CGFont)

    private func darkCGFont(forPage page: Int) -> CGFont? {
        let key = NSNumber(value: page)
        if let cached = cachedDarkCGFonts.object(forKey: key) {
            return cached.font
        }

        let darkFontURL = darkFontDir.appendingPathComponent("p\(page)_dark.ttf")

        // Generate dark font if not cached on disk
        if !FileManager.default.fileExists(atPath: darkFontURL.path) {
            guard let sourceURL = Bundle.main.url(forResource: "p\(page)", withExtension: "ttf"),
                  var fontData = try? Data(contentsOf: sourceURL) else {
                return nil
            }
            Self.invertCPALBlackToWhite(&fontData)
            try? fontData.write(to: darkFontURL)
        }

        // Load directly via CGFont — no registration needed, avoids name collision
        guard let data = try? Data(contentsOf: darkFontURL) as CFData,
              let provider = CGDataProvider(data: data),
              let cgFont = CGFont(provider) else {
            return nil
        }

        cachedDarkCGFonts.setObject(CGFontWrapper(cgFont), forKey: key)
        return cgFont
    }

    // MARK: - Surah Header Font (dark mode)

    func surahHeaderUIFont(size: CGFloat, dark: Bool) -> UIFont {
        if dark, let cgFont = darkSurahHeaderFont() {
            let ctFont = CTFontCreateWithGraphicsFont(cgFont, size, nil, nil)
            return ctFont as UIFont
        }
        return UIFont(name: "QCF_SurahHeader_COLOR", size: size) ?? UIFont.systemFont(ofSize: size)
    }

    private func darkSurahHeaderFont() -> CGFont? {
        if let cached = darkSurahHeaderCGFont {
            return cached
        }

        let darkURL = darkFontDir.appendingPathComponent("SurahHeader_dark.ttf")

        if !FileManager.default.fileExists(atPath: darkURL.path) {
            guard let sourceURL = Bundle.main.url(forResource: "QCF_SurahHeader_COLOR-Regular", withExtension: "ttf"),
                  var fontData = try? Data(contentsOf: sourceURL) else { return nil }
            Self.invertCPALBlackToWhite(&fontData)
            try? fontData.write(to: darkURL)
        }

        guard let data = try? Data(contentsOf: darkURL) as CFData,
              let provider = CGDataProvider(data: data),
              let cgFont = CGFont(provider) else { return nil }

        darkSurahHeaderCGFont = cgFont
        return cgFont
    }

    // MARK: - Theme-aware font selection

    func uiFont(forPage page: Int, size: CGFloat, dark: Bool) -> UIFont {
        if dark, let cgFont = darkCGFont(forPage: page) {
            let ctFont = CTFontCreateWithGraphicsFont(cgFont, size, nil, nil)
            return ctFont as UIFont
        }
        let name = fontName(forPage: page)
        return UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
    }

    // MARK: - Pre-register all light mode page fonts (call during splash)

    func preRegisterAllPageFonts() {
        for page in 1...604 {
            _ = fontName(forPage: page)
        }
    }

    // MARK: - Pre-generate all dark fonts (call during splash)

    // Bump this when CPAL logic changes to force regeneration
    private static let darkFontVersion = "v11"

    func preGenerateDarkFonts() {
        guard !darkFontsReady else { return }

        // Check if already generated with current version
        let markerFile = darkFontDir.appendingPathComponent(".complete_\(Self.darkFontVersion)")
        if FileManager.default.fileExists(atPath: markerFile.path) {
            darkFontsReady = true
            return
        }

        // Clear old cached fonts
        if let files = try? FileManager.default.contentsOfDirectory(at: darkFontDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }

        // Generate dark surah header font
        let darkHeaderURL = darkFontDir.appendingPathComponent("SurahHeader_dark.ttf")
        if !FileManager.default.fileExists(atPath: darkHeaderURL.path) {
            if let sourceURL = Bundle.main.url(forResource: "QCF_SurahHeader_COLOR-Regular", withExtension: "ttf"),
               var fontData = try? Data(contentsOf: sourceURL) {
                Self.invertCPALBlackToWhite(&fontData)
                try? fontData.write(to: darkHeaderURL)
            }
        }

        // Generate dark page fonts
        for page in 1...604 {
            let darkFontURL = darkFontDir.appendingPathComponent("p\(page)_dark.ttf")
            guard !FileManager.default.fileExists(atPath: darkFontURL.path) else { continue }

            guard let sourceURL = Bundle.main.url(forResource: "p\(page)", withExtension: "ttf"),
                  var fontData = try? Data(contentsOf: sourceURL) else { continue }

            Self.invertCPALBlackToWhite(&fontData)
            try? fontData.write(to: darkFontURL)
        }

        // Mark as complete with version
        try? Data().write(to: markerFile)
        // Clear in-memory cache so new fonts are loaded
        cachedDarkCGFonts.removeAllObjects()
        darkSurahHeaderCGFont = nil
        darkFontsReady = true
    }

    // MARK: - CPAL Table Modification

    /// Modifies the CPAL table in-place: black/near-black entries become white.
    /// Tajweed colors (saturated) are preserved.
    private static func invertCPALBlackToWhite(_ data: inout Data) {
        // Parse OpenType table directory
        guard data.count > 12 else { return }
        let numTables = Int(data[4]) << 8 | Int(data[5])

        for i in 0..<numTables {
            let entryOffset = 12 + i * 16
            guard entryOffset + 16 <= data.count else { return }

            let tag = String(bytes: data[entryOffset..<entryOffset+4], encoding: .ascii) ?? ""
            guard tag == "CPAL" else { continue }

            let tableOffset = Int(data[entryOffset+8]) << 24 | Int(data[entryOffset+9]) << 16 |
                              Int(data[entryOffset+10]) << 8 | Int(data[entryOffset+11])

            // CPAL header
            let base = tableOffset
            guard base + 12 <= data.count else { return }

            let numColorRecords = Int(data[base+6]) << 8 | Int(data[base+7])
            let colorRecordOffset = Int(data[base+8]) << 24 | Int(data[base+9]) << 16 |
                                    Int(data[base+10]) << 8 | Int(data[base+11])

            let colorBase = base + colorRecordOffset

            // Each color record is 4 bytes: B, G, R, A
            for j in 0..<numColorRecords {
                let cOffset = colorBase + j * 4
                guard cOffset + 4 <= data.count else { continue }

                let b = Int(data[cOffset])
                let g = Int(data[cOffset + 1])
                let r = Int(data[cOffset + 2])
                let a = Int(data[cOffset + 3])

                guard a > 10 else { continue }

                // Low saturation = grayscale (black, gray, white)
                // High saturation = tajweed colors — leave unchanged
                let maxC = max(r, max(g, b))
                let minC = min(r, min(g, b))
                let saturation = maxC > 0 ? (maxC - minC) * 255 / maxC : 0

                if saturation < 50 {
                    if maxC < 30 {
                        // Black/near-black → white (main text)
                        data[cOffset]     = UInt8(255)
                        data[cOffset + 1] = UInt8(255)
                        data[cOffset + 2] = UInt8(255)
                    } else if maxC > 200 {
                        // White/near-white → #7C0A24 (circle fills)
                        data[cOffset]     = UInt8(0x24) // B
                        data[cOffset + 1] = UInt8(0x0A) // G
                        data[cOffset + 2] = UInt8(0x7C) // R
                    } else {
                        // Mid grays → lighter gray (outlines)
                        let val = min(255, maxC + 60)
                        data[cOffset]     = UInt8(val)
                        data[cOffset + 1] = UInt8(val)
                        data[cOffset + 2] = UInt8(val)
                    }
                }
            }

            // Update the table checksum
            Self.updateTableChecksum(&data, tableEntryOffset: entryOffset, tableOffset: tableOffset,
                                     tableLength: Int(data[entryOffset+12]) << 24 | Int(data[entryOffset+13]) << 16 |
                                     Int(data[entryOffset+14]) << 8 | Int(data[entryOffset+15]))
            return
        }
    }

    /// Recalculates the checksum for a modified OpenType table.
    private static func updateTableChecksum(_ data: inout Data, tableEntryOffset: Int, tableOffset: Int, tableLength: Int) {
        var sum: UInt32 = 0
        let paddedLength = (tableLength + 3) & ~3
        for i in stride(from: tableOffset, to: tableOffset + paddedLength, by: 4) {
            guard i + 4 <= data.count else { break }
            let val = UInt32(data[i]) << 24 | UInt32(data[i+1]) << 16 |
                      UInt32(data[i+2]) << 8 | UInt32(data[i+3])
            sum = sum &+ val
        }
        // Write checksum back to table directory entry (offset + 4)
        let csOffset = tableEntryOffset + 4
        data[csOffset]     = UInt8((sum >> 24) & 0xFF)
        data[csOffset + 1] = UInt8((sum >> 16) & 0xFF)
        data[csOffset + 2] = UInt8((sum >> 8) & 0xFF)
        data[csOffset + 3] = UInt8(sum & 0xFF)
    }
}

// MARK: - SwiftUI Font Extensions

extension Font {
    static func surahHeader(size: CGFloat) -> Font {
        .custom("QCF_SurahHeader_COLOR", size: size)
    }
}
