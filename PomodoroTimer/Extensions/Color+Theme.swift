import SwiftUI
import UIKit

extension Color {
    static let appOrange = Color(red: 1.0, green: 0.55, blue: 0.18)

    static let appBackground = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1)
        }
        return UIColor(red: 1.0, green: 0.97, blue: 0.94, alpha: 1)
    })

    static let appSurface = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.16, green: 0.15, blue: 0.14, alpha: 1)
        }
        return UIColor.white
    })

    static let appFill = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(white: 1, alpha: 0.08)
        }
        return UIColor(red: 0.97, green: 0.93, blue: 0.89, alpha: 1)
    })

    static let appSecondary = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.68, green: 0.66, blue: 0.64, alpha: 1)
        }
        return UIColor(red: 0.48, green: 0.46, blue: 0.44, alpha: 1)
    })

    static let appShadow = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(white: 0, alpha: 0.4)
        }
        return UIColor(red: 0.52, green: 0.32, blue: 0.12, alpha: 0.12)
    })

    static let breakGreen = Color(red: 0.22, green: 0.72, blue: 0.47)
    static let dangerRed = Color(red: 0.96, green: 0.32, blue: 0.28)

    static let timerFocus = appOrange
    static let timerBreak = breakGreen
    static let petAlive = appOrange
    static let petDead = appSecondary

    static var appOrangeGradient: LinearGradient {
        LinearGradient(
            colors: [appOrange, Color(red: 1.0, green: 0.70, blue: 0.28)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
