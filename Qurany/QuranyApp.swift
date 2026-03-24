import SwiftUI

@main
struct QuranyApp: App {
    @State private var dataService = QuranDataService.shared
    @State private var isLoading = true
    @State private var minTimePassed = false

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

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // App logo
                Text("QURAN.")
                    .font(.custom("Oi-Regular", size: 48))
                    .foregroundStyle(.primary)

                // Bismillah
                Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                    .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 22))
                    .foregroundStyle(.secondary)
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
