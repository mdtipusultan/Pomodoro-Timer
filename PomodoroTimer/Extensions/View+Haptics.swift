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
    
    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    func timerStart() {
        guard isEnabled else { return }
        heavyImpact.impactOccurred()
    }

    func timerPause() {
        guard isEnabled else { return }
        lightImpact.impactOccurred()
    }

    func timerStop() {
        guard isEnabled else { return }
        impact.impactOccurred()
    }

    func sessionComplete() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    func sessionFailed() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }

    func buttonTap() {
        guard isEnabled else { return }
        lightImpact.impactOccurred()
    }

    func selection() {
        guard isEnabled else { return }
        selectionFeedback.selectionChanged()
    }

    func petInteraction() {
        guard isEnabled else { return }
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
