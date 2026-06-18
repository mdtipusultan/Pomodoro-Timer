import Combine
import Foundation

#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
#endif

@MainActor
final class AppBlockingService: ObservableObject {
    @Published var isBlocking = false
    @Published var isAuthorized = false
    @Published var strictModeEnabled: Bool {
        didSet { UserDefaults.standard.set(strictModeEnabled, forKey: "strictModeEnabled") }
    }

    #if canImport(FamilyControls)
  @Published var selection = FamilyActivitySelection()
    private let store = ManagedSettingsStore()
    #endif

    init() {
        strictModeEnabled = UserDefaults.standard.bool(forKey: "strictModeEnabled")
    }

    func requestAuthorization() async {
        #if targetEnvironment(simulator)
        isAuthorized = false
        return
        #elseif canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        } catch {
            isAuthorized = false
        }
        #else
        isAuthorized = false
        #endif
    }

    func startBlocking() {
        #if targetEnvironment(simulator)
        isBlocking = true
        return
        #elseif canImport(FamilyControls)
        guard isAuthorized else { return }
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        isBlocking = true
        #endif
    }

    func stopBlocking() {
        #if canImport(FamilyControls) && !targetEnvironment(simulator)
        store.clearAllSettings()
        #endif
        isBlocking = false
    }
}
