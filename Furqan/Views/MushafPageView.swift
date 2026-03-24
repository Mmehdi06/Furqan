import SwiftUI

struct MushafPageView: View {
    let page: QuranPage
    let highlightedAyah: AyahHighlight?
    let onAyahAction: ((AyahAction) -> Void)?
    @Environment(\.readingTheme) private var theme

    init(page: QuranPage, highlightedAyah: AyahHighlight?, onAyahAction: ((AyahAction) -> Void)? = nil) {
        self.page = page
        self.highlightedAyah = highlightedAyah
        self.onAyahAction = onAyahAction
    }

    private let totalLines: CGFloat = 15

    var body: some View {
        GeometryReader { geo in
            let lineHeight = geo.size.height / totalLines
            let fontSize = lineHeight * 0.55

            VStack(spacing: 0) {
                ForEach(page.lines) { line in
                    MushafLineView(
                        line: line,
                        fontSize: fontSize,
                        pageNumber: page.id,
                        highlightedAyah: highlightedAyah,
                        onAyahAction: onAyahAction
                    )
                    .frame(height: lineHeight)
                }

                if page.lines.count < Int(totalLines) {
                    Spacer(minLength: 0)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 52)
        .background(theme.pageBackground)
    }
}
