import SwiftUI

struct PetAnimationView: View {
    let petType: PetType
    let animationState: AppState.PetAnimationState
    @State private var shakeOffset: CGFloat = 0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            if showConfetti {
                ConfettiView()
            }

            Image(systemName: petType.systemImage)
                .font(.system(size: 64))
                .foregroundStyle(petType.color)
                .offset(x: shakeOffset)
                .modifier(PetSymbolEffect(state: animationState))
                .onChange(of: animationState) { _, newState in
                    handleStateChange(newState)
                }
        }
        .onAppear {
            handleStateChange(animationState)
        }
    }

    private func handleStateChange(_ state: AppState.PetAnimationState) {
        switch state {
        case .failed:
            withAnimation(.default.repeatCount(5, autoreverses: true)) {
                shakeOffset = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shakeOffset = 0
            }
        case .success:
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showConfetti = false
            }
        default:
            shakeOffset = 0
            showConfetti = false
        }
    }
}

private struct PetSymbolEffect: ViewModifier {
    let state: AppState.PetAnimationState

    func body(content: Content) -> some View {
        switch state {
        case .idle:
            content.symbolEffect(.pulse, options: .repeating)
        case .focusing:
            content.symbolEffect(.breathe, options: .repeating)
        case .breakTime:
            content.symbolEffect(.pulse, options: .repeating.speed(0.5))
        case .success:
            content.symbolEffect(.bounce, value: state)
        case .failed:
            content.symbolEffect(.disappear, options: .nonRepeating)
        }
    }
}

private struct ConfettiView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill([Color.appOrange, .yellow, .pink, .purple, .cyan].randomElement() ?? .orange)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: animate ? CGFloat.random(in: -80...80) : 0,
                        y: animate ? CGFloat.random(in: -80...80) : 0
                    )
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animate = true
            }
        }
    }
}

#Preview {
    PetAnimationView(petType: .cat, animationState: .focusing)
}
