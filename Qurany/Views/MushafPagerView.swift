import SwiftUI

struct MushafPagerView: View {
    let pages: [QuranPage]
    @State private var currentPage: Int = 1

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(pages) { page in
                MushafPageView(page: page)
                    .tag(page.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .environment(\.layoutDirection, .rightToLeft)
        .ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .bottom) {
            pageIndicator
        }
    }

    private var pageIndicator: some View {
        Text("\(currentPage)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 8)
    }
}
