import SwiftUI

struct FloatingTimerView: View {
    let timeRemaining: TimeInterval
    let petType: PetType

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: petType.systemImage)
                .foregroundStyle(Color.appOrange)
            Text(timeRemaining.formattedTimer)
                .font(.caption.bold().monospacedDigit())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    FloatingTimerView(timeRemaining: 1234, petType: .cat)
}
