import Combine
import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    @Published var isReachable = false
    @Published var lastSyncedTimeRemaining: TimeInterval = 0
    @Published var lastSyncedState: String = "idle"

    static let shared = WatchConnectivityService()

    private override init() {
        super.init()
        #if !targetEnvironment(simulator)
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        #endif
    }

    func sendTimerUpdate(state: String, timeRemaining: TimeInterval, petType: String) {
        #if targetEnvironment(simulator)
        return
        #else
        guard WCSession.default.activationState == .activated else { return }
        let message: [String: Any] = [
            "state": state,
            "timeRemaining": timeRemaining,
            "petType": petType
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil)
        } else {
            try? WCSession.default.updateApplicationContext(message)
        }
        #endif
    }
}

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
        }
    }
}
