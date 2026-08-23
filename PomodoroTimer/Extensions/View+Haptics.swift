import SwiftUI
import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()
    
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    private init() {
        impact.prepare()
        lightImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
        selectionFeedback.prepare()
    }
    
    func timerStart() {
        heavyImpact.impactOccurred()
    }
    
    func timerPause() {
        lightImpact.impactOccurred()
    }
    
    func timerStop() {
        impact.impactOccurred()
    }
    
    func sessionComplete() {
        notification.notificationOccurred(.success)
    }
    
    func sessionFailed() {
        notification.notificationOccurred(.error)
    }
    
    func buttonTap() {
        lightImpact.impactOccurred()
    }
    
    func selection() {
        selectionFeedback.selectionChanged()
    }
    
    func petInteraction() {
        lightImpact.impactOccurred()
    }
}

extension View {
    func performHaptic(_ haptic: @escaping () -> Void, enabled: Bool = true) {
        if enabled {
            haptic()
        }
    }
}
