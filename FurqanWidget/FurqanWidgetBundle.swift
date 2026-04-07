import WidgetKit
import SwiftUI

@main
struct FurqanWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyAyahWidget()
        ReadingProgressWidget()
    }
}
