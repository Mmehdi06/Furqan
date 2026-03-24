import SwiftUI

struct MushafLineView: View {
    let line: QuranLine
    let fontSize: CGFloat
    let pageNumber: Int
    let highlightedAyah: AyahHighlight?
    let onAyahAction: ((AyahAction) -> Void)?
    @Environment(\.readingTheme) private var theme

    init(line: QuranLine, fontSize: CGFloat, pageNumber: Int, highlightedAyah: AyahHighlight?, onAyahAction: ((AyahAction) -> Void)? = nil) {
        self.line = line
        self.fontSize = fontSize
        self.pageNumber = pageNumber
        self.highlightedAyah = highlightedAyah
        self.onAyahAction = onAyahAction
    }

    var body: some View {
        switch line.lineType {
        case .surahName:
            surahHeaderView
        case .basmallah:
            basmallahView
        case .ayah:
            ayahLineView
        }
    }

    // MARK: - Surah Header

    private var surahHeaderView: some View {
        GeometryReader { geo in
            Text(surahHeaderGlyph)
                .font(.surahHeader(size: geo.size.width * 0.9))
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private static let surahHeaderCodepoints: [UInt32] = [
        0xFC45, 0xFC46, 0xFC47, 0xFC4A, 0xFC4B, 0xFC4E, 0xFC4F, 0xFC51,
        0xFC52, 0xFC53, 0xFC55, 0xFC56, 0xFC58, 0xFC5A, 0xFC5B, 0xFC5C,
        0xFC5D, 0xFC5E, 0xFC61, 0xFC62, 0xFC64, 0xFB51, 0xFB52, 0xFB54,
        0xFB55, 0xFB57, 0xFB58, 0xFB5A, 0xFB5B, 0xFB5D, 0xFB5E, 0xFB60,
        0xFB61, 0xFB63, 0xFB64, 0xFB66, 0xFB67, 0xFB69, 0xFB6A, 0xFB6C,
        0xFB6D, 0xFB6F, 0xFB70, 0xFB72, 0xFB73, 0xFB75, 0xFB76, 0xFB78,
        0xFB79, 0xFB7B, 0xFB7C, 0xFB7E, 0xFB7F, 0xFB81, 0xFB82, 0xFB84,
        0xFB85, 0xFB87, 0xFB88, 0xFB8A, 0xFB8B, 0xFB8D, 0xFB8E, 0xFB90,
        0xFB91, 0xFB93, 0xFB94, 0xFB96, 0xFB97, 0xFB99, 0xFB9A, 0xFB9C,
        0xFB9D, 0xFB9F, 0xFBA0, 0xFBA2, 0xFBA3, 0xFBA5, 0xFBA6, 0xFBA8,
        0xFBA9, 0xFBAB, 0xFBAC, 0xFBAE, 0xFBAF, 0xFBB1, 0xFBB2, 0xFBB4,
        0xFBB5, 0xFBB7, 0xFBB8, 0xFBBA, 0xFBBB, 0xFBBD, 0xFBBE, 0xFBC0,
        0xFBC1, 0xFBD3, 0xFBD4, 0xFBD6, 0xFBD7, 0xFBD9, 0xFBDA, 0xFBDC,
        0xFBDD, 0xFBDF, 0xFBE0, 0xFBE2, 0xFBE3, 0xFBE5, 0xFBE6, 0xFBE8,
        0xFBE9, 0xFBEB
    ]

    private var surahHeaderGlyph: String {
        guard let surahNum = line.surahNumber,
              surahNum >= 1, surahNum <= 114,
              let scalar = UnicodeScalar(Self.surahHeaderCodepoints[surahNum - 1])
        else { return "" }
        return String(scalar)
    }

    // MARK: - Basmallah

    private var basmallahView: some View {
        Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
            .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: fontSize))
            .foregroundStyle(theme.textColor)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Ayah Line with context menu

    private func lineIsHighlighted() -> Bool {
        guard let highlight = highlightedAyah else { return false }
        return line.ayahsOnLine.contains { $0.surah == highlight.surah && $0.ayah == highlight.ayah }
    }

    @ViewBuilder
    private var ayahLineView: some View {
        let ayahs = line.ayahsOnLine

        QPCTextLine(
            words: line.words,
            pageNumber: pageNumber,
            fontSize: fontSize,
            isCentered: line.isCentered,
            selectiveInvert: theme.needsSelectiveInvert
        )
        .background(
            Group {
                if lineIsHighlighted() {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.swiftHighlightColor)
                        .padding(.horizontal, -4)
                        .padding(.vertical, 1)
                }
            }
        )
        .contentShape(Rectangle())
        .contextMenu {
            if ayahs.count == 1, let a = ayahs.first {
                // Single ayah — show actions directly
                ayahMenuItems(surah: a.surah, ayah: a.ayah)
            } else {
                // Multiple ayahs — show sub-menu per ayah
                ForEach(ayahs, id: \.ayah) { a in
                    Menu("Ayah \(a.surah):\(a.ayah)") {
                        ayahMenuItems(surah: a.surah, ayah: a.ayah)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func ayahMenuItems(surah: Int, ayah: Int) -> some View {
        let isBookmarked = BookmarkManager.shared.isAyahBookmarked(surah: surah, ayah: ayah)

        Button {
            onAyahAction?(.showTafsir(surah: surah, ayah: ayah))
        } label: {
            Label("Tafsir (\(surah):\(ayah))", systemImage: "book.pages")
        }

        Button {
            onAyahAction?(.showSurahInfo(surah: surah))
        } label: {
            Label("Surah Info", systemImage: "info.circle")
        }

        Divider()

        Button {
            onAyahAction?(.toggleBookmark(surah: surah, ayah: ayah, page: pageNumber))
        } label: {
            Label(
                isBookmarked ? "Remove Bookmark" : "Bookmark Ayah",
                systemImage: isBookmarked ? "bookmark.slash.fill" : "bookmark"
            )
        }
    }
}

// MARK: - Ayah Actions

enum AyahAction {
    case showTafsir(surah: Int, ayah: Int)
    case showSurahInfo(surah: Int)
    case toggleBookmark(surah: Int, ayah: Int, page: Int)
}

// MARK: - QPC Glyph Text Rendering (UIKit)

struct QPCTextLine: UIViewRepresentable {
    let words: [QuranWord]
    let pageNumber: Int
    let fontSize: CGFloat
    let isCentered: Bool
    var selectiveInvert: Bool = false

    func makeUIView(context: Context) -> QPCGlyphView {
        QPCGlyphView()
    }

    func updateUIView(_ view: QPCGlyphView, context: Context) {
        let font = QuranFontManager.shared.uiFont(forPage: pageNumber, size: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = isCentered ? .center : .justified
        paragraphStyle.baseWritingDirection = .rightToLeft
        paragraphStyle.lineBreakMode = .byClipping

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        let attributed = NSMutableAttributedString()
        for word in words {
            attributed.append(NSAttributedString(string: word.text, attributes: baseAttributes))
        }

        view.update(attributedText: attributed, selectiveInvert: selectiveInvert)
    }
}

// MARK: - Custom UIView for selective color font inversion

/// Renders QPC color font glyphs and selectively inverts only black/gray pixels
/// while preserving tajweed color markers (red, blue, green, etc.)
final class QPCGlyphView: UIView {
    private let label = UILabel()
    private let imageView = UIImageView()
    private var needsSelectiveInvert = false
    private var currentText: NSAttributedString?

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.clipsToBounds = true
        label.isUserInteractionEnabled = false
        isUserInteractionEnabled = false

        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleToFill
        imageView.isHidden = true

        addSubview(label)
        addSubview(imageView)

        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        label.intrinsicContentSize
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        label.sizeThatFits(size)
    }

    func update(attributedText: NSAttributedString, selectiveInvert: Bool) {
        let textChanged = currentText != attributedText
        let invertChanged = needsSelectiveInvert != selectiveInvert
        guard textChanged || invertChanged else { return }

        currentText = attributedText
        needsSelectiveInvert = selectiveInvert
        label.attributedText = attributedText
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
        imageView.frame = bounds

        if needsSelectiveInvert {
            label.isHidden = false
            label.layoutIfNeeded()

            guard bounds.width > 0, bounds.height > 0 else { return }

            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            let image = renderer.image { ctx in
                label.layer.render(in: ctx.cgContext)
            }

            label.isHidden = true
            imageView.isHidden = false

            if let cgImage = image.cgImage,
               let processed = Self.invertBlackPixels(in: cgImage) {
                imageView.image = UIImage(cgImage: processed, scale: image.scale, orientation: .up)
            }
        } else {
            label.isHidden = false
            imageView.isHidden = true
        }
    }

    /// Inverts only low-saturation (black/gray) pixels to white,
    /// preserving high-saturation tajweed color pixels.
    private static func invertBlackPixels(in cgImage: CGImage) -> CGImage? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return nil }

        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        let count = width * height * bytesPerPixel

        for i in stride(from: 0, to: count, by: bytesPerPixel) {
            let a = pixels[i + 3]
            guard a > 10 else { continue }

            let r = Int(pixels[i])
            let g = Int(pixels[i + 1])
            let b = Int(pixels[i + 2])

            let maxC = max(r, max(g, b))
            let minC = min(r, min(g, b))

            // Saturation check: low saturation = black/gray/white text
            // High saturation = tajweed colored marks — leave unchanged
            let saturation = maxC > 0 ? (maxC - minC) * 255 / maxC : 0
            if saturation < 50 {
                pixels[i]     = UInt8(255 - r)
                pixels[i + 1] = UInt8(255 - g)
                pixels[i + 2] = UInt8(255 - b)
            }
        }

        return context.makeImage()
    }
}
