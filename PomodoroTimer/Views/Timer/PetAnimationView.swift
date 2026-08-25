import SpriteKit
import SwiftUI

struct PetAnimationView: View {
    let petType: PetType
    let animationState: AppState.PetAnimationState
    var growth: Double = 0
    var playsIntro: Bool = false

    @State private var scene = PetGrowthScene(size: CGSize(width: 150, height: 150))
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            if showConfetti {
                ConfettiView()
            }

            SpriteView(scene: scene, options: [.allowsTransparency])
                .frame(width: 150, height: 150)
                .accessibilityHidden(true)
        }
        .frame(height: 140)
        .onAppear {
            scene.configure(
                imageName: petType.imageName,
                glow: UIColor(petType.color),
                growth: growth,
                state: sceneState
            )
            if playsIntro {
                scene.playIntroGrowth()
            }
            handleStateChange(animationState)
        }
        .onChange(of: petType) { _, newType in
            scene.updatePet(imageName: newType.imageName, glow: UIColor(newType.color))
        }
        .onChange(of: growth) { _, newGrowth in
            scene.updateGrowth(newGrowth)
        }
        .onChange(of: animationState) { _, newState in
            scene.updateState(newState.spriteState)
            handleStateChange(newState)
        }
    }

    private var sceneState: PetGrowthScene.VisualState {
        animationState.spriteState
    }

    private func handleStateChange(_ state: AppState.PetAnimationState) {
        switch state {
        case .success:
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showConfetti = false
                }
            }
        case .idle, .failed:
            showConfetti = false
        default:
            break
        }
    }
}

private extension AppState.PetAnimationState {
    var spriteState: PetGrowthScene.VisualState {
        switch self {
        case .idle: return .idle
        case .focusing: return .focusing
        case .breakTime: return .breakTime
        case .success: return .success
        case .failed: return .failed
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
    PetAnimationView(petType: .cat, animationState: .focusing, growth: 0.6)
}
