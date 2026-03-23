import SwiftUI

@main
struct QuranyApp: App {
    @State private var dataService = QuranDataService.shared
    @State private var isLoading = true

    init() {
        QuranFonts.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    ProgressView("Loading Quran...")
                        .font(.headline)
                } else {
                    MushafPagerView(pages: dataService.pages)
                }
            }
            .task {
                dataService.loadAll()
                isLoading = false
            }
        }
    }
}
