import SwiftUI

struct MushafLineView: View {
    let line: QuranLine
    let fontSize: CGFloat
    let pageNumber: Int
    let highlightedAyah: AyahHighlight?
    let onAyahAction: ((AyahAction) -> Void)?

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
            .frame(maxWidth: .infinity)
    }

    // MARK: - Ayah Line with context menu

    @ViewBuilder
    private var ayahLineView: some View {
        let ayahs = line.ayahsOnLine

        QPCTextLine(
            words: line.words,
            pageNumber: pageNumber,
            fontSize: fontSize,
            isCentered: line.isCentered,
            highlightedAyah: highlightedAyah
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
    let highlightedAyah: AyahHighlight?

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.clipsToBounds = true
        label.isUserInteractionEnabled = false
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
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
            var attrs = baseAttributes
            if let highlight = highlightedAyah,
               word.surah == highlight.surah && word.ayah == highlight.ayah {
                attrs[.backgroundColor] = UIColor.systemYellow.withAlphaComponent(0.35)
            }
            attributed.append(NSAttributedString(string: word.text, attributes: attrs))
        }

        label.attributedText = attributed
    }
}
