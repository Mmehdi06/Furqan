import SwiftUI

struct AyahDeepLink: Equatable {
    let surah: Int
    let ayah: Int

    init?(url: URL) {
        guard url.scheme == "furqan",
              url.host == "ayah",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let surahValue = components.queryItems?.first(where: { $0.name == "surah" })?.value,
              let ayahValue = components.queryItems?.first(where: { $0.name == "ayah" })?.value,
              let surah = Int(surahValue),
              let ayah = Int(ayahValue)
        else { return nil }

        self.surah = surah
        self.ayah = ayah
    }
}

@main
struct FurqanApp: App {
    @State private var dataService = QuranDataService.shared
    @State private var isLoading = true
    @State private var minTimePassed = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @StateObject private var themeManager = ThemeManager.shared
    @State private var pendingDeepLink: AyahDeepLink?

    init() {
        QuranFontManager.shared.registerStaticFonts()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoading || !minTimePassed {
                    SplashScreen()
                } else if showOnboarding {
                    OnboardingView {
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showOnboarding = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    MushafPagerView(pages: dataService.pages, surahs: dataService.surahs, pendingDeepLink: $pendingDeepLink)
                        .transition(.opacity)
                }
            }
            .environment(\.readingTheme, themeManager.current)
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.current.colorScheme)
            .animation(.easeOut(duration: 0.4), value: isLoading)
            .animation(.easeOut(duration: 0.4), value: minTimePassed)
            .animation(.easeOut(duration: 0.5), value: showOnboarding)
            .onOpenURL { url in
                if let deepLink = AyahDeepLink(url: url) {
                    pendingDeepLink = deepLink
                }
            }
            .task {
                // Start minimum 2s timer and data loading in parallel
                async let timer: () = Task.sleep(nanoseconds: 2_000_000_000)

                dataService.loadAll()
                _ = BookmarkManager.shared
                TafsirService.shared.warmUp()
                QuranFontManager.shared.preGenerateDarkFonts()
                QuranFontManager.shared.preRegisterAllPageFonts()

                // Warm up search (open DB + run a trivial query)
                let searchService = QuranSearchService.shared
                _ = searchService.search(query: " ", limit: 1)

                // Pre-load keyboard in background
                KeyboardWarmUp.prepare()

                isLoading = false

                try? await timer
                minTimePassed = true
            }
        }
    }
}

// MARK: - Keyboard Pre-warm

enum KeyboardWarmUp {
    static func prepare() {
        DispatchQueue.main.async {
            let field = UITextField(frame: .zero)
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first
            else { return }
            window.addSubview(field)
            field.becomeFirstResponder()
            field.resignFirstResponder()
            field.removeFromSuperview()
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
