import SwiftUI

struct WatchTimerView: View {
    @State private var timeRemaining: TimeInterval = 25 * 60
    @State private var isRunning = false
    @State private var petType: PetType = .cat

    private var progress: Double {
        max(0, min(1, 1 - (timeRemaining / (25 * 60))) )
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
                isRunning.toggle()
            }
            .tint(.orange)
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
