import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            Circle()
                .stroke(Color.black.opacity(0.05), lineWidth: 2)
                .padding(lineWidth / 2 + 4)
        }
    }
}

#Preview {
    TimerRingView(progress: 0.6, color: .appOrange, lineWidth: 12)
        .frame(width: 280, height: 280)
}
