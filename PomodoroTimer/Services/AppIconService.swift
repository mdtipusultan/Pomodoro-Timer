import UIKit

enum AppIconService {
    static func apply(selection: String) {
        guard UIApplication.shared.supportsAlternateIcons else { return }

        let iconName = alternateIconName(for: selection)
        guard UIApplication.shared.alternateIconName != iconName else { return }

        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error {
                print("App icon change failed: \(error.localizedDescription)")
            }
        }
    }

    private static func alternateIconName(for selection: String) -> String? {
        switch selection {
        case "midnight": return "Midnight"
        case "forest": return "Forest"
        default: return nil
        }
    }
}
