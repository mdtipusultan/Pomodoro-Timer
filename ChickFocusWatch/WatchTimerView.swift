import SwiftUI

struct WatchTimerView: View {
    @State private var timeRemaining: TimeInterval = 25 * 60
    @State private var isRunning = false
    @State private var petType: PetType = .cat

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: petType.systemImage)
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text(timeRemaining.formattedTimer)
                .font(.system(.title2, design: .rounded).monospacedDigit())

            Button(isRunning ? "Stop" : "Start") {
                isRunning.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("watchTimerUpdate"))) { notification in
            if let time = notification.userInfo?["timeRemaining"] as? TimeInterval {
                timeRemaining = time
            }
            if let state = notification.userInfo?["state"] as? String {
                isRunning = state != "idle"
            }
            if let pet = notification.userInfo?["petType"] as? String {
                petType = PetType(rawValue: pet) ?? .cat
            }
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
