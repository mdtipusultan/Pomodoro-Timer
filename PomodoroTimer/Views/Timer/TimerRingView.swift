import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.14), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.7), color, color.opacity(0.85)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.35), radius: 6, y: 0)
                .animation(.linear(duration: 1), value: progress)

            Circle()
                .stroke(Color.appFill, lineWidth: 2)
                .padding(lineWidth / 2 + 6)
        }
    }
}

#Preview {
    TimerRingView(progress: 0.6, color: .appOrange, lineWidth: 12)
        .frame(width: 280, height: 280)
}
