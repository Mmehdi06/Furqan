import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    @State private var appeared = false

    private let totalPages = 8

    var body: some View {
        ZStack {
            backgroundGradient

            TabView(selection: $currentPage) {
                WelcomePage(appeared: appeared)
                    .tag(0)
                MushafPage(appeared: appeared, isActive: currentPage == 1)
                    .tag(1)
                ContextMenuPage(isActive: currentPage == 2)
                    .tag(2)
                SearchPage(isActive: currentPage == 3)
                    .tag(3)
                BookmarksPage(isActive: currentPage == 4)
                    .tag(4)
                ThemesPage(isActive: currentPage == 5)
                    .tag(5)
                FeaturesPage(isActive: currentPage == 6)
                    .tag(6)
                StartPage(isActive: currentPage == 7, onStart: onComplete)
                    .tag(7)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                Spacer()
                PageIndicator(currentPage: currentPage, totalPages: totalPages)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                ForEach(0..<15, id: \.self) { i in
                    Circle()
                        .fill(
                            [Color(red: 0.4, green: 0.3, blue: 0.1),
                             Color(red: 0.2, green: 0.15, blue: 0.05),
                             Color(red: 0.3, green: 0.2, blue: 0.08)][i % 3]
                        )
                        .frame(width: CGFloat.random(in: 2...6))
                        .opacity(appeared ? Double.random(in: 0.2...0.5) : 0)
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: appeared
                        )
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Page Indicator

private struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Color.white : Color.white.opacity(0.3))
                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    let appeared: Bool
    @State private var shimmerOffset: CGFloat = -200
    @State private var bismillahVisible = false
    @State private var subtitleVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Text("FURQAN.")
                    .font(.custom("Oi-Regular", size: 52))
                    .foregroundStyle(.white)

                Text("FURQAN.")
                    .font(.custom("Oi-Regular", size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.6), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .mask(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white, .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                    )
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)

            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 22))
                .foregroundStyle(Color(red: 0.85, green: 0.75, blue: 0.55))
                .opacity(bismillahVisible ? 1 : 0)
                .offset(y: bismillahVisible ? 0 : 20)
                .padding(.top, 40)

            Text("Your Quran Companion")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(4)
                .textCase(.uppercase)
                .opacity(subtitleVisible ? 1 : 0)
                .padding(.top, 24)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.5)) {
                bismillahVisible = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(1.0)) {
                subtitleVisible = true
            }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false).delay(1.5)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Page 2: Mushaf

private struct MushafPage: View {
    let appeared: Bool
    let isActive: Bool
    @State private var linesRevealed = 0
    @State private var textVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title above the mushaf
            Text("Authentic mushaf layout")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .opacity(textVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: textVisible)

            Text("with tajweed color coding")
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 6)
                .opacity(textVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.2), value: textVisible)
                .padding(.bottom, 20)

            // Decorative top line
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Color(red: 0.85, green: 0.75, blue: 0.55), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
                .padding(.horizontal, 40)
                .opacity(isActive ? 1 : 0)
                .animation(.easeIn(duration: 0.6), value: isActive)

            // Page 356, lines 7-15
            GeometryReader { geo in
                let pages = QuranDataService.shared.pages
                let page = pages.count >= 365 ? pages[364] : pages.first
                let visibleLines = page.map { Array($0.lines.dropFirst(6)) } ?? []
                let lineCount = CGFloat(visibleLines.count)
                let lineHeight = lineCount > 0 ? geo.size.height / lineCount : geo.size.height / 9
                let fontSize = lineHeight * 0.55

                VStack(spacing: 0) {
                    ForEach(Array(visibleLines.enumerated()), id: \.element.id) { index, line in
                        MushafLineView(
                            line: line,
                            fontSize: fontSize,
                            pageNumber: 365,
                            highlightedAyah: nil
                        )
                        .frame(height: lineHeight)
                        .opacity(linesRevealed > index ? 1 : 0)
                        .offset(y: linesRevealed > index ? 0 : 12)
                        .animation(
                            .easeOut(duration: 0.5).delay(Double(index) * 0.12),
                            value: linesRevealed
                        )
                    }
                }
            }
            .frame(height: 380)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            // Decorative bottom line
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Color(red: 0.85, green: 0.75, blue: 0.55), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .opacity(isActive ? 1 : 0)
                .animation(.easeIn(duration: 0.6), value: isActive)

            Spacer()
            Spacer()
        }
        .environment(\.readingTheme, .amoled)
        .onChange(of: isActive) { _, active in
            if active {
                let pages = QuranDataService.shared.pages
                let page = pages.count >= 356 ? pages[355] : pages.first
                let lineCount = max((page?.lines.count ?? 15) - 6, 0)
                linesRevealed = lineCount
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(lineCount) * 0.12 + 0.3) {
                    textVisible = true
                }
            }
        }
    }
}

// MARK: - Page 3: Context Menu Feature

private struct ContextMenuPage: View {
    let isActive: Bool
    @State private var visible = false
    @State private var menuVisible = false
    @State private var activeItem = -1

    private let menuItems: [(icon: String, title: String, separated: Bool)] = [
        ("character.book.closed", "Translation (25:63)", false),
        ("book.pages", "Tafsir (25:63)", false),
        ("info.circle", "Surah Info", false),
        ("bookmark", "Bookmark Ayah", true),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Long press any verse")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .opacity(visible ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: visible)

            Text("to access tafsir, translation & more")
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 6)
                .opacity(visible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: visible)

            // Mock context menu card
            VStack(spacing: 0) {
                // Preview area - mock Quran line
                HStack {
                    Spacer()
                    Text("وَعِبَادُ ٱلرَّحْمَـٰنِ ٱلَّذِينَ يَمْشُونَ عَلَى ٱلْأَرْضِ هَوْنًا")
                        .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 20))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(Color(white: 0.93), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Menu items
                VStack(spacing: 0) {
                    ForEach(Array(menuItems.enumerated()), id: \.offset) { index, item in
                        if item.separated {
                            Divider()
                                .frame(height: 6)
                                .overlay(Color(white: 0.92))
                        } else if index > 0 {
                            Divider().padding(.leading, 16)
                        }

                        HStack {
                            Text(item.title)
                                .font(.system(size: 16))
                                .foregroundStyle(.black)
                            Spacer()
                            Image(systemName: item.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(activeItem == index ? Color(white: 0.9) : Color.white)
                        .opacity(menuVisible ? 1 : 0)
                        .offset(y: menuVisible ? 0 : -8)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.08 + 0.3),
                            value: menuVisible
                        )
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 6)
            }
            .padding(.horizontal, 40)
            .padding(.top, 32)
            .scaleEffect(menuVisible ? 1 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: menuVisible)

            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, active in
            if active {
                visible = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    menuVisible = true
                }
                // Animate through menu items
                for i in 0..<menuItems.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(i) * 0.5) {
                        withAnimation(.easeInOut(duration: 0.2)) { activeItem = i }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + Double(i) * 0.5) {
                        withAnimation(.easeInOut(duration: 0.2)) { activeItem = -1 }
                    }
                }
            }
        }
    }
}

// MARK: - Page 4: Search Feature

private struct SearchPage: View {
    let isActive: Bool
    @State private var visible = false
    @State private var searchText = ""
    @State private var resultsVisible = false
    @State private var typingIndex = 0

    private let searchWord = "فرقان"

    private let results: [(page: String, ref: String, surah: String, text: String)] = [
        ("Page 8", "(2:53)", "البقرة", "وَإِذْ ءَاتَيْنَا مُوسَى ٱلْكِتَـٰبَ وَٱلْفُرْقَانَ لَعَلَّكُمْ تَهْتَدُونَ"),
        ("Page 50", "(3:4)", "آل عمران", "مِن قَبْلُ هُدًى لِّلنَّاسِ وَأَنزَلَ ٱلْفُرْقَانَ"),
        ("Page 359", "(25:1)", "الفرقان", "تَبَارَكَ ٱلَّذِى نَزَّلَ ٱلْفُرْقَانَ عَلَىٰ عَبْدِهِۦ"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Instant search")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .opacity(visible ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: visible)

            Text("find any verse across the entire Quran")
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 6)
                .opacity(visible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: visible)

            // Mock search UI
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(searchText)
                        .font(.system(size: 17))
                        .foregroundStyle(.black)
                    if !searchText.isEmpty {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(white: 0.93), in: RoundedRectangle(cornerRadius: 10))

                if resultsVisible {
                    // Result count
                    HStack {
                        Text("\(results.count) results")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                    // Results
                    ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(result.page)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(result.surah)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                Text(result.ref)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Text(result.text)
                                .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 18))
                                .foregroundStyle(.black)
                                .lineLimit(2)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                        .padding(.vertical, 8)
                        .opacity(resultsVisible ? 1 : 0)
                        .offset(y: resultsVisible ? 0 : 10)
                        .animation(
                            .easeOut(duration: 0.4).delay(Double(index) * 0.12),
                            value: resultsVisible
                        )

                        if index < results.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 28)
            .padding(.top, 28)

            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, active in
            if active {
                visible = true
                // Type out the search word character by character
                let chars = Array(searchWord)
                for i in 0..<chars.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(i) * 0.15) {
                        searchText = String(chars[0...i])
                    }
                }
                // Show results after typing completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(chars.count) * 0.15 + 0.3) {
                    withAnimation { resultsVisible = true }
                }
            }
        }
    }
}

// MARK: - Page 5: Bookmarks Feature

private struct BookmarksPage: View {
    let isActive: Bool
    @State private var visible = false
    @State private var bookmarksVisible = false
    @State private var pulseBookmark = false

    private let bookmarks: [(surah: String, ref: String, page: String, date: String)] = [
        ("البقرة", "(2:255)", "Page 42", "25 March 2026"),
        ("الكهف", "(18:10)", "Page 293", "24 March 2026"),
        ("يس", "(36:1)", "Page 440", "23 March 2026"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated bookmark icon
            ZStack {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.orange)
                    .scaleEffect(pulseBookmark ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: pulseBookmark
                    )

                Image(systemName: "bookmark.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.orange.opacity(0.3))
                    .blur(radius: 12)
                    .scaleEffect(pulseBookmark ? 1.3 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: pulseBookmark
                    )
            }
            .opacity(visible ? 1 : 0)
            .animation(.easeOut(duration: 0.5), value: visible)

            Text("Save your place")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .padding(.top, 16)
                .opacity(visible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: visible)

            Text("bookmark any ayah for quick access")
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 6)
                .opacity(visible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: visible)

            // Mock bookmarks list
            VStack(spacing: 0) {
                HStack {
                    Text("AYAH BOOKMARKS")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ForEach(Array(bookmarks.enumerated()), id: \.offset) { index, bookmark in
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(bookmark.surah) \(bookmark.ref)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.blue)
                            Text(bookmark.page)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(bookmark.date)
                            .font(.system(size: 12))
                            .foregroundStyle(.orange.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(white: 0.97))
                    .opacity(bookmarksVisible ? 1 : 0)
                    .offset(x: bookmarksVisible ? 0 : 30)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.15 + 0.2),
                        value: bookmarksVisible
                    )

                    if index < bookmarks.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 28)
            .padding(.top, 24)

            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, active in
            if active {
                visible = true
                pulseBookmark = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bookmarksVisible = true
                }
            }
        }
    }
}

// MARK: - Page 6: Features Recap

private struct FeaturesPage: View {
    let isActive: Bool
    @State private var cardsVisible = false

    private let features: [(icon: String, title: String, desc: String, color: Color)] = [
        ("magnifyingglass", "Search", "Find any verse instantly", Color(red: 0.3, green: 0.6, blue: 1.0)),
        ("bookmark.fill", "Bookmarks", "Save your favorite ayahs", Color(red: 1.0, green: 0.6, blue: 0.2)),
        ("book.pages", "Tafsir", "Ibn Kathir commentary", Color(red: 0.5, green: 0.8, blue: 0.4)),
        ("character.book.closed", "Translation", "French translation", Color(red: 0.8, green: 0.5, blue: 1.0)),
        ("info.circle", "Surah Info", "Context and background", Color(red: 1.0, green: 0.4, blue: 0.5)),
        ("moon.fill", "Themes", "Light, dark, sepia & AMOLED", Color(red: 0.85, green: 0.75, blue: 0.55)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Everything you need")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .opacity(cardsVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: cardsVisible)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    FeatureCard(icon: feature.icon, title: feature.title, desc: feature.desc, color: feature.color)
                        .opacity(cardsVisible ? 1 : 0)
                        .offset(y: cardsVisible ? 0 : 30)
                        .scaleEffect(cardsVisible ? 1 : 0.8)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1),
                            value: cardsVisible
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)

            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, active in
            if active { cardsVisible = true }
        }
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let desc: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text(desc)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Page 7: Themes

private struct ThemesPage: View {
    let isActive: Bool
    @State private var activeTheme = 0
    @State private var visible = false
    @State private var autoTimer: Timer?

    private static let themes: [(name: String, bg: Color, text: Color, icon: String)] = [
        ("Light", Color(red: 1, green: 0.99, blue: 0.97), .black, "sun.max.fill"),
        ("Dark", Color(red: 0.15, green: 0.15, blue: 0.17), .white, "moon.fill"),
        ("Sepia", Color(red: 0.96, green: 0.93, blue: 0.87), Color(red: 0.26, green: 0.20, blue: 0.14), "book.fill"),
        ("AMOLED", .black, .white, "circle.fill"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Reading themes")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .opacity(visible ? 1 : 0)

            TabView(selection: $activeTheme) {
                ForEach(Array(Self.themes.enumerated()), id: \.offset) { index, theme in
                    themeCard(theme: theme)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 340)
            .padding(.top, 16)
            .onChange(of: activeTheme) { _, _ in
                restartAutoTimer()
            }

            HStack(spacing: 16) {
                ForEach(Array(Self.themes.enumerated()), id: \.offset) { index, theme in
                    Circle()
                        .fill(index == activeTheme ? theme.bg : Color.white.opacity(0.2))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .scaleEffect(index == activeTheme ? 1.3 : 1)
                        .animation(.spring(response: 0.3), value: activeTheme)
                        .onTapGesture {
                            withAnimation { activeTheme = index }
                            restartAutoTimer()
                        }
                }
            }
            .padding(.top, 16)

            Text("Comfortable reading, day and night")
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 16)
                .opacity(visible ? 1 : 0)

            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, active in
            if active {
                visible = true
                restartAutoTimer()
            } else {
                autoTimer?.invalidate()
                autoTimer = nil
            }
        }
    }

    private func themeCard(theme: (name: String, bg: Color, text: Color, icon: String)) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(theme.bg)
            .frame(width: 240, height: 300)
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: theme.icon)
                        .font(.system(size: 30))
                        .foregroundStyle(theme.text.opacity(0.4))

                    Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                        .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 22))
                        .foregroundStyle(theme.text)
                        .multilineTextAlignment(.center)

                    Text(theme.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(theme.text.opacity(0.6))
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
            )
            .shadow(color: .white.opacity(0.05), radius: 20)
    }

    private func restartAutoTimer() {
        autoTimer?.invalidate()
        autoTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                activeTheme = (activeTheme + 1) % Self.themes.count
            }
        }
    }
}

// MARK: - Page 8: Start

private struct StartPage: View {
    let isActive: Bool
    let onStart: () -> Void
    @State private var visible = false
    @State private var buttonScale: CGFloat = 1
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 20))
                .foregroundStyle(Color(red: 0.85, green: 0.75, blue: 0.55).opacity(0.6))
                .opacity(visible ? 1 : 0)
                .animation(.easeOut(duration: 0.8), value: visible)

            Text("Begin your journey")
                .font(.system(size: 26, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .padding(.top, 24)
                .opacity(visible ? 1 : 0)
                .offset(y: visible ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: visible)

            Text("with the words of Allah")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 8)
                .opacity(visible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: visible)

            Button(action: onStart) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.85, green: 0.75, blue: 0.55))
                        .frame(width: 220, height: 56)
                        .blur(radius: 20)
                        .opacity(glowOpacity)

                    Text("Start Reading")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(.black)
                        .frame(width: 220, height: 56)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.75, blue: 0.55),
                                    Color(red: 0.75, green: 0.65, blue: 0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }
            }
            .scaleEffect(buttonScale)
            .padding(.top, 48)
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 30)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: visible)

            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, active in
            if active {
                visible = true
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.6
                }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.5)) {
                    buttonScale = 1.03
                }
            }
        }
    }
}
