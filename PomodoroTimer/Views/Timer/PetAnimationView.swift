import SwiftUI

struct PetAnimationView: View {
    let petType: PetType
    let animationState: AppState.PetAnimationState
    @State private var shakeOffset: CGFloat = 0
    @State private var showConfetti = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            if showConfetti {
                ConfettiView()
            }
            
            Circle()
                .fill(petType.color.opacity(backgroundOpacity))
                .frame(width: 100, height: 100)
                .blur(radius: 8)
                .scaleEffect(scale)

            Image(petType.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .shadow(color: petType.color.opacity(0.25), radius: 8, y: 4)
                .offset(x: shakeOffset)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .modifier(PetSymbolEffect(state: animationState))
                .onChange(of: animationState) { _, newState in
                    handleStateChange(newState)
                }
        }
        .frame(height: 100)
        .onAppear {
            handleStateChange(animationState)
        }
    }
    
    private var backgroundOpacity: Double {
        switch animationState {
        case .idle: return 0.14
        case .focusing: return 0.22
        case .breakTime: return 0.18
        case .success: return 0.28
        case .failed: return 0.10
        }
    }

    private func handleStateChange(_ state: AppState.PetAnimationState) {
        switch state {
        case .failed:
            withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)) {
                shakeOffset = 8
            }
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 0.85
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                shakeOffset = 0
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
        case .success:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                scale = 1.2
            }
            withAnimation(.easeInOut(duration: 0.4)) {
                rotation = 15
            }
            showConfetti = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.0
                    rotation = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showConfetti = false
                }
            }
        case .focusing:
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.05
            }
        case .breakTime:
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
        case .idle:
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                rotation = 0
            }
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
    private let particles = (0..<16).map { _ in
        ConfettiParticle(
            color: [Color.appOrange, .yellow, .pink, .purple, .cyan, .green].randomElement() ?? .orange,
            angle: Double.random(in: 0...360),
            distance: CGFloat.random(in: 60...100)
        )
    }

    var body: some View {
        ZStack {
            ForEach(particles.indices, id: \.self) { index in
                let particle = particles[index]
                Circle()
                    .fill(particle.color)
                    .frame(width: CGFloat.random(in: 6...10), height: CGFloat.random(in: 6...10))
                    .offset(
                        x: animate ? particle.distance * cos(particle.angle * .pi / 180) : 0,
                        y: animate ? particle.distance * sin(particle.angle * .pi / 180) : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 0.3 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.8)) {
                animate = true
            }
        }
    }
}

private struct ConfettiParticle {
    let color: Color
    let angle: Double
    let distance: CGFloat
}

#Preview {
    PetAnimationView(petType: .cat, animationState: .focusing)
}
