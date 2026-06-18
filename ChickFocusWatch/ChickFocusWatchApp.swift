import SwiftUI

@main
struct ChickFocusWatchApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                WatchTimerView()
                WatchPetView(pets: [])
            }
        }
    }
}
