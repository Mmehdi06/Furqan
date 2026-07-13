import SwiftUI
import CoreText

struct MushafLineView: View {
    let line: QuranLine
    let fontSize: CGFloat
    let pageNumber: Int
    let highlightedAyah: AyahHighlight?
    let onAyahAction: ((AyahAction) -> Void)?
    let allLines: [QuranLine]
    @Environment(\.readingTheme) private var theme

    init(line: QuranLine, fontSize: CGFloat, pageNumber: Int, highlightedAyah: AyahHighlight?, onAyahAction: ((AyahAction) -> Void)? = nil, allLines: [QuranLine] = []) {
        self.line = line
        self.fontSize = fontSize
        self.pageNumber = pageNumber
        self.highlightedAyah = highlightedAyah
        self.onAyahAction = onAyahAction
        self.allLines = allLines
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

    // MARK: - Ayah Line

    private func lineIsHighlighted() -> Bool {
        guard let highlight = highlightedAyah else { return false }
        return line.ayahsOnLine.contains { $0.surah == highlight.surah && $0.ayah == highlight.ayah }
    }

    @ViewBuilder
    private var ayahLineView: some View {
        QPCTextLine(
            words: line.words,
            pageNumber: pageNumber,
            fontSize: fontSize,
            isCentered: line.isCentered,
            highlightedAyah: lineIsHighlighted() ? highlightedAyah : nil,
            highlightColor: theme.uiHighlightColor,
            isDarkMode: theme.needsSelectiveInvert,
            allLines: allLines,
            pageBackground: UIColor(theme.pageBackground),
            onAyahAction: onAyahAction,
            theme: theme
        )
    }
}

// MARK: - Ayah Actions

enum AyahAction {
    case showTranslation(surah: Int, ayah: Int)
    case showTafsir(surah: Int, ayah: Int)
    case showSurahInfo(surah: Int)
    case saveAyah(surah: Int, ayah: Int, page: Int)
    case removeSavedAyah(surah: Int, ayah: Int)
    case editNote(surah: Int, ayah: Int, page: Int)
}

// MARK: - QPC Text Line (UILabel subclass with context menu)

struct QPCTextLine: UIViewRepresentable {
    let words: [QuranWord]
    let pageNumber: Int
    let fontSize: CGFloat
    let isCentered: Bool
    var highlightedAyah: AyahHighlight? = nil
    var highlightColor: UIColor? = nil
    var isDarkMode: Bool = false
    var allLines: [QuranLine] = []
    var pageBackground: UIColor = .black
    var onAyahAction: ((AyahAction) -> Void)? = nil
    var theme: ReadingTheme = .light

    func makeUIView(context: Context) -> QPCLabel {
        let label = QPCLabel()
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.clipsToBounds = true
        label.isUserInteractionEnabled = true
        return label
    }

    func updateUIView(_ label: QPCLabel, context: Context) {
        // Always update context menu properties (lightweight)
        label.allLines = allLines
        label.pageBgColor = pageBackground
        label.onAyahAction = onAyahAction
        label.highlightColorForMenu = highlightColor
        label.currentTheme = theme
        label.words = words
        label.pageNumber = pageNumber
        label.fontSize = fontSize

        // Skip expensive attributed string rebuild if nothing visual changed
        if label.lastRenderedDarkMode == isDarkMode &&
           label.lastRenderedHighlight == highlightedAyah &&
           label.lastRenderedWordCount == words.count {
            label.isDarkMode = isDarkMode
            return
        }

        label.isDarkMode = isDarkMode
        label.lastRenderedHighlight = highlightedAyah
        label.lastRenderedDarkMode = isDarkMode
        label.lastRenderedWordCount = words.count

        let font = QuranFontManager.shared.uiFont(forPage: pageNumber, size: fontSize, dark: isDarkMode)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = isCentered ? .center : .justified
        paragraphStyle.baseWritingDirection = .rightToLeft
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        // Use a system font for space characters to get consistent spacing
        // QPC page fonts have wildly different space glyph widths
        let spaceFont = UIFont.systemFont(ofSize: fontSize * 0.3)

        let attributed = NSMutableAttributedString()
        var ranges: [(range: NSRange, wordIndex: Int)] = []

        for (index, word) in words.enumerated() {
            var attrs = baseAttributes
            if let highlight = highlightedAyah, let color = highlightColor,
               word.surah == highlight.surah && word.ayah == highlight.ayah {
                attrs[.backgroundColor] = color
            }

            let startIndex = attributed.length
            attributed.append(NSAttributedString(string: word.text, attributes: attrs))
            let endIndex = attributed.length
            ranges.append((range: NSRange(location: startIndex, length: endIndex - startIndex), wordIndex: index))

            if index < words.count - 1 {
                // Use system font space for consistent width across all page fonts
                var spaceAttrs = baseAttributes
                spaceAttrs[.font] = spaceFont
                if let highlight = highlightedAyah, let color = highlightColor {
                    let nextWord = words[index + 1]
                    // Highlight only the leading space before a highlighted word,
                    // not the trailing space after the last highlighted word.
                    if nextWord.surah == highlight.surah && nextWord.ayah == highlight.ayah {
                        spaceAttrs[.backgroundColor] = color
                    }
                }
                attributed.append(NSAttributedString(string: " ", attributes: spaceAttrs))
            }
        }

        label.attributedText = attributed
        label.wordRanges = ranges
    }
}

// MARK: - UILabel subclass with context menu interaction

class QPCLabel: UILabel, UIContextMenuInteractionDelegate {

    var words: [QuranWord] = []
    var pageNumber: Int = 1
    var fontSize: CGFloat = 20
    var isDarkMode: Bool = false
    var allLines: [QuranLine] = []
    var pageBgColor: UIColor = .black
    var onAyahAction: ((AyahAction) -> Void)? = nil
    var highlightColorForMenu: UIColor? = nil
    var currentTheme: ReadingTheme = .light
    var wordRanges: [(range: NSRange, wordIndex: Int)] = []

    // Track last rendered state to skip unnecessary attributed string rebuilds
    var lastRenderedHighlight: AyahHighlight?
    var lastRenderedDarkMode: Bool?
    var lastRenderedWordCount: Int = -1

    private var menuInteraction: UIContextMenuInteraction?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupContextMenu()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupContextMenu()
    }

    private func setupContextMenu() {
        let interaction = UIContextMenuInteraction(delegate: self)
        addInteraction(interaction)
        menuInteraction = interaction
    }

    // MARK: - Hit testing: map point to ayah

    private func ayahAtPoint(_ point: CGPoint) -> (surah: Int, ayah: Int)? {
        guard let attributedText = attributedText, !words.isEmpty else { return nil }

        // Create CTLine from the attributed text
        let ctLine = CTLineCreateWithAttributedString(attributedText)

        // The label may scale text to fit — compute the scale factor
        let fullSize = CTLineGetBoundsWithOptions(ctLine, []).size
        let scale = fullSize.width > 0 ? bounds.width / fullSize.width : 1.0
        let actualScale = min(scale, 1.0) // adjustsFontSizeToFitWidth only shrinks

        // Convert tap point to text coordinate space
        // For RTL justified text, the text fills the full width
        // CTLine uses a coordinate system where x=0 is the text start (right side for RTL)
        // But CTLineGetStringIndexForPosition expects x in the line's coordinate space
        let textPoint = CGPoint(x: point.x / actualScale, y: point.y)

        let charIndex = CTLineGetStringIndexForPosition(ctLine, textPoint)

        // Find which word this character belongs to
        if charIndex != kCFNotFound {
            for entry in wordRanges {
                if charIndex >= entry.range.location && charIndex < entry.range.location + entry.range.length {
                    let word = words[entry.wordIndex]
                    return (surah: word.surah, ayah: word.ayah)
                }
                // Also check the space after this word (attribute it to this word)
                let spaceAfter = entry.range.location + entry.range.length
                if charIndex == spaceAfter && entry.wordIndex < words.count - 1 {
                    let word = words[entry.wordIndex]
                    return (surah: word.surah, ayah: word.ayah)
                }
            }
        }

        // Fallback: divide label width proportionally among words
        // Each QPC glyph has roughly similar advance width
        let tapX = point.x
        let wordCount = words.count
        guard wordCount > 0 else { return nil }

        // For RTL: right side = first word, left side = last word
        let segmentWidth = bounds.width / CGFloat(wordCount)
        let index = Int((bounds.width - tapX) / segmentWidth)
        let clampedIndex = max(0, min(wordCount - 1, index))
        let word = words[clampedIndex]
        return (surah: word.surah, ayah: word.ayah)
    }

    // MARK: - Lines containing ayah

    private func linesContainingAyah(surah: Int, ayah: Int) -> [QuranLine] {
        allLines.filter { line in
            line.lineType == .ayah &&
            line.words.contains { $0.surah == surah && $0.ayah == ayah }
        }
    }

    // MARK: - Build preview for ayah using same SwiftUI views

    private func makePreviewVC(surah: Int, ayah: Int) -> UIViewController {
        let ayahLines = linesContainingAyah(surah: surah, ayah: ayah)
        let lineHeight = fontSize / 0.55
        let highlight = AyahHighlight(surah: surah, ayah: ayah)
        let width = bounds.width
        let dark = isDarkMode
        let page = pageNumber
        let fs = fontSize
        let hlColor = highlightColorForMenu
        let bgColor = pageBgColor
        let theme = currentTheme

        let previewContent = VStack(spacing: 0) {
            ForEach(ayahLines) { line in
                QPCTextLine(
                    words: line.words,
                    pageNumber: page,
                    fontSize: fs,
                    isCentered: line.isCentered,
                    highlightedAyah: highlight,
                    highlightColor: hlColor,
                    isDarkMode: dark
                )
                .frame(width: width, height: lineHeight)
            }
        }
        .background(Color(bgColor))
        .environment(\.readingTheme, theme)

        let vc = UIHostingController(rootView: previewContent)
        vc.view.backgroundColor = bgColor
        let totalHeight = CGFloat(ayahLines.count) * lineHeight
        vc.preferredContentSize = CGSize(width: width, height: totalHeight)
        return vc
    }

    // MARK: - UIContextMenuInteractionDelegate

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let ayah = ayahAtPoint(location) else { return nil }

        let surah = ayah.surah
        let ayahNum = ayah.ayah
        let pageNum = pageNumber

        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: { [weak self] in
                guard let self = self else { return nil }
                return self.makePreviewVC(surah: surah, ayah: ayahNum)
            },
            actionProvider: { [weak self] _ in
                guard let self = self else { return nil }

                let savedAyah = BookmarkManager.shared.savedAyah(surah: surah, ayah: ayahNum)
                let isSaved = savedAyah != nil
                let hasNote = savedAyah?.hasNote ?? false

                let translation = UIAction(
                    title: "Translation (\(surah):\(ayahNum))",
                    image: UIImage(systemName: "character.book.closed")
                ) { _ in
                    self.onAyahAction?(.showTranslation(surah: surah, ayah: ayahNum))
                }

                let tafsir = UIAction(
                    title: "Tafsir (\(surah):\(ayahNum))",
                    image: UIImage(systemName: "book.pages")
                ) { _ in
                    self.onAyahAction?(.showTafsir(surah: surah, ayah: ayahNum))
                }

                let surahInfo = UIAction(
                    title: "Surah Info",
                    image: UIImage(systemName: "info.circle")
                ) { _ in
                    self.onAyahAction?(.showSurahInfo(surah: surah))
                }

                let saveAction = UIAction(
                    title: isSaved ? "Remove Saved Ayah" : "Save Ayah",
                    image: UIImage(systemName: isSaved ? "bookmark.slash.fill" : "bookmark")
                ) { _ in
                    if isSaved {
                        self.onAyahAction?(.removeSavedAyah(surah: surah, ayah: ayahNum))
                    } else {
                        self.onAyahAction?(.saveAyah(surah: surah, ayah: ayahNum, page: pageNum))
                    }
                }

                let noteAction = UIAction(
                    title: hasNote ? "Edit Note" : "Add Note",
                    image: UIImage(systemName: "note.text")
                ) { _ in
                    self.onAyahAction?(.editNote(surah: surah, ayah: ayahNum, page: pageNum))
                }

                let infoMenu = UIMenu(title: "", options: .displayInline, children: [translation, tafsir, surahInfo])
                let bookmarkMenu = UIMenu(title: "", options: .displayInline, children: [saveAction, noteAction])

                return UIMenu(title: "", children: [infoMenu, bookmarkMenu])
            }
        )
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        return UITargetedPreview(view: self, parameters: params)
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        return UITargetedPreview(view: self, parameters: params)
    }
}
