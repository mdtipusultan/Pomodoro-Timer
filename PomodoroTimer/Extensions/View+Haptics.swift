import SwiftUI
import UIKit

extension View {
    func timerStartHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func sessionCompleteHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func sessionFailedHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func selectionHaptic() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
