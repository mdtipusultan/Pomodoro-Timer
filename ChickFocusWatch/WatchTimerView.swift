import SwiftUI
import WatchConnectivity

struct WatchTimerView: View {
    @State private var timeRemaining: TimeInterval = 25 * 60
    @State private var isRunning = false
    @State private var petType: PetType = .cat
    @StateObject private var session = WatchSessionClient.shared

    private var progress: Double {
        max(0, min(1, 1 - (timeRemaining / (25 * 60))))
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: isRunning ? max(progress, 0.02) : 1)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: petType.systemImage)
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            .frame(width: 72, height: 72)

            Text(timeRemaining.formattedTimer)
                .font(.system(.title2, design: .rounded).monospacedDigit())

            Button(isRunning ? "Stop" : "Start") {
                session.send(action: isRunning ? "stop" : "start")
                isRunning.toggle()
            }
            .tint(.orange)
        }
        .onAppear { session.activate() }
        .onReceive(session.$timeRemaining) { timeRemaining = $0 }
        .onReceive(session.$isRunning) { isRunning = $0 }
        .onReceive(session.$petType) { petType = $0 }
    }
}

@MainActor
final class WatchSessionClient: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionClient()
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var isRunning = false
    @Published var petType: PetType = .cat

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(action: String) {
        guard WCSession.default.activationState == .activated else { return }
        WCSession.default.sendMessage(["action": action], replyHandler: nil, errorHandler: nil)
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            apply(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            apply(applicationContext)
        }
    }

    private func apply(_ message: [String: Any]) {
        if let time = message["timeRemaining"] as? TimeInterval {
            timeRemaining = time
        }
        if let state = message["state"] as? String {
            isRunning = state != "idle"
        }
        if let pet = message["petType"] as? String {
            petType = PetType(rawValue: pet) ?? .cat
        }
    }
}

private extension TimeInterval {
    var formattedTimer: String {
        let total = max(0, Int(self))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

#Preview {
    WatchTimerView()
}
