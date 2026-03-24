import SwiftUI

@main
struct FurqanApp: App {
    @State private var dataService = QuranDataService.shared
    @State private var isLoading = true
    @State private var minTimePassed = false
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        QuranFontManager.shared.registerStaticFonts()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoading || !minTimePassed {
                    SplashScreen()
                } else {
                    MushafPagerView(pages: dataService.pages, surahs: dataService.surahs)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.4), value: isLoading || !minTimePassed)
            .environment(\.readingTheme, themeManager.current)
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.current.colorScheme)
            .task {
                // Start minimum 2s timer and data loading in parallel
                async let timer: () = Task.sleep(nanoseconds: 2_000_000_000)

                dataService.loadAll()
                _ = QuranSearchService.shared
                _ = BookmarkManager.shared
                TafsirService.shared.warmUp()
                isLoading = false

                try? await timer
                minTimePassed = true
            }
        }
    }
}

// MARK: - Splash Screen

struct SplashScreen: View {
    @State private var opacity: Double = 0
    @Environment(\.readingTheme) private var theme

    var body: some View {
        ZStack {
            theme.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // App logo
                Text("FURQAN.")
                    .font(.custom("Oi-Regular", size: 48))
                    .foregroundStyle(theme.textColor)

                // Bismillah
                Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                    .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 22))
                    .foregroundStyle(theme.secondaryTextColor)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
        }
    }
}
