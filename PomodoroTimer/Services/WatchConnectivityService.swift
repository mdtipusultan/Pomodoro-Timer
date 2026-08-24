import Combine
import Foundation
import WatchConnectivity

extension Notification.Name {
    static let watchDidRequestStart = Notification.Name("watchDidRequestStart")
    static let watchDidRequestStop = Notification.Name("watchDidRequestStop")
}

@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    @Published var isReachable = false
    @Published var lastSyncedTimeRemaining: TimeInterval = 0
    @Published var lastSyncedState: String = "idle"

    static let shared = WatchConnectivityService()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendTimerUpdate(state: String, timeRemaining: TimeInterval, petType: String) {
        guard WCSession.default.activationState == .activated else { return }
        let message: [String: Any] = [
            "state": state,
            "timeRemaining": timeRemaining,
            "petType": petType
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            try? WCSession.default.updateApplicationContext(message)
        }
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

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let action = message["action"] as? String
        Task { @MainActor in
            switch action {
            case "start":
                NotificationCenter.default.post(name: .watchDidRequestStart, object: nil)
            case "stop":
                NotificationCenter.default.post(name: .watchDidRequestStop, object: nil)
            default:
                break
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let time = applicationContext["timeRemaining"] as? TimeInterval {
                lastSyncedTimeRemaining = time
            }
            if let state = applicationContext["state"] as? String {
                lastSyncedState = state
            }
        }
    }
}
