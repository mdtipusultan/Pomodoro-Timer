import SwiftData
import SwiftUI

@main
struct ChickFocusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var storeKit = StoreKitService()
    @State private var timerService = TimerService()
    @State private var soundService = SoundService()
    @State private var appState = AppState()
    @State private var settingsViewModel = SettingsViewModel()
    // FAMILY_CONTROLS_DISABLED
    // @State private var appBlockingService = AppBlockingService()

    var sharedModelContainer: ModelContainer = {
        do {
            return try PersistenceService.makeModelContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            SplashView(hasCompletedOnboarding: $hasCompletedOnboarding)
            .environment(storeKit)
            .environment(timerService)
            .environment(soundService)
            .environment(appState)
            .environment(settingsViewModel)
            // FAMILY_CONTROLS_DISABLED
            // .environmentObject(appBlockingService)
            .tint(.appOrange)
            .preferredColorScheme(settingsViewModel.colorScheme)
            .onAppear {
                PersistenceService.seedDefaultTagsIfNeeded(context: sharedModelContainer.mainContext)
                settingsViewModel.applySavedAppIcon()
                settingsViewModel.applyDailyReminder()
                Task { await storeKit.loadProducts() }
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background:
                    timerService.handleBackground()
                    FloatingTimerManager.shared.hide()
                case .active:
                    timerService.handleForeground()
                    FloatingTimerManager.shared.hide()
                default:
                    break
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
