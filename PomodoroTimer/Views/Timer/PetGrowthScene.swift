import SpriteKit
import UIKit

final class PetGrowthScene: SKScene {
    private var petNode: SKSpriteNode?
    private var glowNode: SKShapeNode?
    private var sparkleEmitter: SKEmitterNode?

    private var petImageName = "PetCat"
    private var glowColor = UIColor.systemOrange
    private var growth: CGFloat = 0
    private var visualState: VisualState = .idle
    private var lastSparkleMilestone: Int = -1

    private let kittenScale: CGFloat = 0.42
    private let catScale: CGFloat = 1.18

    enum VisualState {
        case idle, focusing, breakTime, success, failed
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        isUserInteractionEnabled = false
        view.allowsTransparency = true
        view.backgroundColor = .clear
        setupIfNeeded()
        layoutNodes()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutNodes()
    }

    func configure(imageName: String, glow: UIColor, growth: Double, state: VisualState) {
        petImageName = imageName
        glowColor = glow
        self.growth = CGFloat(clamped(growth))
        visualState = state
        setupIfNeeded()
        refreshTexture()
        applyGrowth(animated: false)
        applyStateMotion()
    }

    func updateGrowth(_ value: Double) {
        let next = CGFloat(clamped(value))
        let previous = growth
        growth = next
        applyGrowth(animated: true)

        let milestone = Int(next * 3)
        if visualState == .focusing, milestone > lastSparkleMilestone, milestone >= 1 {
            lastSparkleMilestone = milestone
            burstSparkles()
        }
        if previous < 0.98, next >= 0.98 {
            burstSparkles()
        }
    }

    func updateState(_ state: VisualState) {
        let changed = visualState != state
        visualState = state
        if state == .idle || state == .failed {
            lastSparkleMilestone = -1
        }
        applyGrowth(animated: true)
        if changed {
            applyStateMotion()
        }
    }

    func updatePet(imageName: String, glow: UIColor) {
        petImageName = imageName
        glowColor = glow
        refreshTexture()
        glowNode?.strokeColor = glow.withAlphaComponent(0.0)
        glowNode?.fillColor = glow.withAlphaComponent(0.22)
    }

    func playIntroGrowth(duration: TimeInterval = 0.85) {
        visualState = .focusing
        growth = 0
        applyGrowth(animated: false)
        lastSparkleMilestone = -1
        let action = SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self else { return }
            self.growth = CGFloat(elapsed / duration)
            self.applyGrowth(animated: false)
        }
        run(action, withKey: "introGrowth")
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.burstSparkles()
        }
    }

    private func setupIfNeeded() {
        guard petNode == nil else { return }

        let glow = SKShapeNode(circleOfRadius: 48)
        glow.fillColor = glowColor.withAlphaComponent(0.22)
        glow.strokeColor = .clear
        glow.glowWidth = 18
        glow.zPosition = 0
        glowNode = glow
        addChild(glow)

        let pet = SKSpriteNode(texture: makeTexture(), size: CGSize(width: 88, height: 88))
        pet.zPosition = 1
        petNode = pet
        addChild(pet)

        let emitter = makeSparkleEmitter()
        emitter.zPosition = 2
        sparkleEmitter = emitter
        addChild(emitter)

        startIdleBob()
    }

    private func layoutNodes() {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        petNode?.position = center
        glowNode?.position = center
        sparkleEmitter?.position = center
    }

    private func refreshTexture() {
        petNode?.texture = makeTexture()
    }

    private func makeTexture() -> SKTexture {
        if let image = UIImage(named: petImageName) {
            return SKTexture(image: image)
        }
        let config = UIImage.SymbolConfiguration(pointSize: 120, weight: .medium)
        let symbol = UIImage(systemName: "cat.fill", withConfiguration: config)?
            .withTintColor(glowColor, renderingMode: .alwaysOriginal)
        return SKTexture(image: symbol ?? UIImage())
    }

    private func targetScale() -> CGFloat {
        let grown = kittenScale + (catScale - kittenScale) * growth
        switch visualState {
        case .idle:
            return kittenScale
        case .focusing:
            return grown
        case .breakTime:
            return max(grown, catScale * 0.94)
        case .success:
            return catScale
        case .failed:
            return kittenScale * 0.88
        }
    }

    private func applyGrowth(animated: Bool) {
        guard let petNode, let glowNode else { return }
        let scale = targetScale()
        let glowScale = 0.7 + (scale * 0.55)
        if animated {
            petNode.run(.scale(to: scale, duration: 0.35), withKey: "grow")
            glowNode.run(.scale(to: glowScale, duration: 0.35), withKey: "glowGrow")
        } else {
            petNode.setScale(scale)
            glowNode.setScale(glowScale)
        }
        glowNode.fillColor = glowColor.withAlphaComponent(0.14 + Double(growth) * 0.16)
    }

    private func applyStateMotion() {
        guard let petNode else { return }
        petNode.removeAction(forKey: "state")
        petNode.zRotation = 0

        switch visualState {
        case .idle:
            startIdleBob()
        case .focusing:
            startIdleBob()
            let sway = SKAction.sequence([
                SKAction.rotate(toAngle: 0.05, duration: 0.9),
                SKAction.rotate(toAngle: -0.05, duration: 0.9)
            ])
            petNode.run(.repeatForever(sway), withKey: "state")
        case .breakTime:
            startIdleBob()
            let nap = SKAction.sequence([
                SKAction.rotate(toAngle: 0.12, duration: 1.4),
                SKAction.rotate(toAngle: 0.04, duration: 1.4)
            ])
            petNode.run(.repeatForever(nap), withKey: "state")
        case .success:
            burstSparkles()
            let hop = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 16, duration: 0.16),
                SKAction.moveBy(x: 0, y: -16, duration: 0.2),
                SKAction.moveBy(x: 0, y: 10, duration: 0.12),
                SKAction.moveBy(x: 0, y: -10, duration: 0.16)
            ])
            petNode.run(hop, withKey: "state")
            startIdleBob()
        case .failed:
            let shake = SKAction.sequence([
                SKAction.moveBy(x: 8, y: 0, duration: 0.05),
                SKAction.moveBy(x: -16, y: 0, duration: 0.05),
                SKAction.moveBy(x: 8, y: 0, duration: 0.05)
            ])
            petNode.run(.repeat(shake, count: 5), withKey: "state")
        }
    }

    private func startIdleBob() {
        guard let petNode else { return }
        petNode.removeAction(forKey: "bob")
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 1.05),
            SKAction.moveBy(x: 0, y: -5, duration: 1.05)
        ])
        petNode.run(.repeatForever(bob), withKey: "bob")
    }

    private func burstSparkles() {
        guard let sparkleEmitter else { return }
        sparkleEmitter.particleColor = glowColor
        sparkleEmitter.numParticlesToEmit = 22
        sparkleEmitter.particleBirthRate = 80
        sparkleEmitter.resetSimulation()
        run(.wait(forDuration: 0.28)) {
            sparkleEmitter.particleBirthRate = 0
        }
    }

    private func makeSparkleEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = circleTexture()
        emitter.particleBirthRate = 0
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 0.7
        emitter.particleLifetimeRange = 0.25
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 70
        emitter.particleSpeedRange = 36
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -1.3
        emitter.particleScale = 0.14
        emitter.particleScaleRange = 0.06
        emitter.particleScaleSpeed = -0.12
        emitter.particleColor = glowColor
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        emitter.targetNode = self
        return emitter
    }

    private func circleTexture() -> SKTexture {
        let size: CGFloat = 16
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { _ in
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()
        }
        return SKTexture(image: image)
    }

    private func clamped(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}
