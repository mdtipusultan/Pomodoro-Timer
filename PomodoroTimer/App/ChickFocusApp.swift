import SwiftData
import SwiftUI

@main
struct ChickFocusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var storeKit = StoreKitService()
    @State private var timerService = TimerService()
    @State private var soundService = SoundService()
    @State private var appState = AppState()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var appBlockingService = AppBlockingService()

    var sharedModelContainer: ModelContainer = {
        do {
            return try PersistenceService.makeModelContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    SplashView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .environment(storeKit)
            .environment(timerService)
            .environment(soundService)
            .environment(appState)
            .environment(settingsViewModel)
            .environmentObject(appBlockingService)
            .preferredColorScheme(settingsViewModel.colorScheme)
            .onAppear {
                PersistenceService.seedDefaultTagsIfNeeded(context: sharedModelContainer.mainContext)
                settingsViewModel.applySavedAppIcon()
                Task { await storeKit.loadProducts() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appDidEnterBackground)) { _ in
                timerService.handleBackground()
                if timerService.isRunning {
                    FloatingTimerManager.shared.show(
                        timeRemaining: timerService.timeRemaining,
                        petType: appState.selectedPetType
                    ) {}
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appWillEnterForeground)) { _ in
                timerService.handleForeground()
                FloatingTimerManager.shared.hide()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
