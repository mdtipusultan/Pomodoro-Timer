import Combine
import Foundation

// FAMILY_CONTROLS_DISABLED — uncomment block below to re-enable Screen Time app blocking.
// #if canImport(FamilyControls)
// import FamilyControls
// import ManagedSettings
// #endif

@MainActor
final class AppBlockingService: ObservableObject {
    @Published var isBlocking = false
    @Published var isAuthorized = false
    @Published var strictModeEnabled: Bool {
        didSet { UserDefaults.standard.set(strictModeEnabled, forKey: "strictModeEnabled") }
    }

    // FAMILY_CONTROLS_DISABLED
    // #if canImport(FamilyControls)
    // @Published var selection = FamilyActivitySelection()
    // private let store = ManagedSettingsStore()
    // #endif

    init() {
        strictModeEnabled = UserDefaults.standard.bool(forKey: "strictModeEnabled")
        // FAMILY_CONTROLS_DISABLED
        // #if canImport(FamilyControls)
        // if let data = UserDefaults.standard.data(forKey: AppGroup.Keys.familyActivitySelection),
        //    let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
        //     selection = saved
        // }
        // #endif
    }

    func requestAuthorization() async {
        // FAMILY_CONTROLS_DISABLED
        // #if targetEnvironment(simulator)
        // isAuthorized = false
        // return
        // #elseif canImport(FamilyControls)
        // do {
        //     try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        //     isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        // } catch {
        //     isAuthorized = false
        // }
        // #else
        isAuthorized = false
        // #endif
    }

    func startBlocking() {
        // FAMILY_CONTROLS_DISABLED
        // persistSelection()
        // #if targetEnvironment(simulator)
        // isBlocking = true
        // return
        // #elseif canImport(FamilyControls)
        // guard isAuthorized else { return }
        // store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        // store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        // isBlocking = true
        // #endif
    }

    func persistSelection() {
        // FAMILY_CONTROLS_DISABLED
        // #if canImport(FamilyControls)
        // if let data = try? JSONEncoder().encode(selection) {
        //     UserDefaults.standard.set(data, forKey: AppGroup.Keys.familyActivitySelection)
        // }
        // #endif
    }

    func stopBlocking() {
        // FAMILY_CONTROLS_DISABLED
        // #if canImport(FamilyControls) && !targetEnvironment(simulator)
        // store.clearAllSettings()
        // #endif
        isBlocking = false
    }
}
