import SwiftUI
import UIKit

struct MushafLineView: View {
    let line: QuranLine
    let fontSize: CGFloat

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
        Text(surahNameGlyph)
            .font(.surahName(size: fontSize * 2.2))
            .frame(maxWidth: .infinity)
    }

    private var surahNameGlyph: String {
        guard let surahNum = line.surahNumber, surahNum >= 1, surahNum <= 114 else { return "" }
        let scalar = UnicodeScalar(0xE000 + surahNum)!
        return String(scalar)
    }

    // MARK: - Basmallah

    private var basmallahView: some View {
        Text("بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ")
            .font(.quranText(size: fontSize))
            .frame(maxWidth: .infinity)
    }

    // MARK: - Ayah Line

    private var ayahLineView: some View {
        let text = line.words.map(\.text).joined(separator: " ")
        return JustifiedTextLine(
            text: text,
            fontSize: fontSize,
            isCentered: line.isCentered
        )
    }
}

// MARK: - UIKit Justified Text

struct JustifiedTextLine: UIViewRepresentable {
    let text: String
    let fontSize: CGFloat
    let isCentered: Bool

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        let font = UIFont(name: "quran-common", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = isCentered ? .center : .justified
        paragraphStyle.baseWritingDirection = .rightToLeft
        paragraphStyle.lineBreakMode = .byClipping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        label.attributedText = NSAttributedString(string: text, attributes: attributes)
    }
}
