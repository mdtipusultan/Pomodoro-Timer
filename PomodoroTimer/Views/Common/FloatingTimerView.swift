import SwiftUI

struct FloatingTimerView: View {
    let timeRemaining: TimeInterval
    let petType: PetType

    var body: some View {
        HStack(spacing: 8) {
            Image(petType.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
            Text(timeRemaining.formattedTimer)
                .font(.caption.bold().monospacedDigit())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.appOrange.opacity(0.25), lineWidth: 1))
        .shadow(color: Color.appShadow, radius: 6, y: 2)
    }
}

#Preview {
    FloatingTimerView(timeRemaining: 1234, petType: .cat)
}
