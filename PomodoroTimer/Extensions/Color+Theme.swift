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

    // Farm scene palette. Light renders a sunny day, dark renders dusk.
    private static func farmTone(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let tone = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: tone.0, green: tone.1, blue: tone.2, alpha: 1)
        })
    }

    static let farmSkyTop = farmTone(
        light: (0.51, 0.79, 0.96),
        dark: (0.07, 0.09, 0.21)
    )

    static let farmSkyBottom = farmTone(
        light: (0.85, 0.94, 0.99),
        dark: (0.20, 0.19, 0.35)
    )

    static let farmHillFar = farmTone(
        light: (0.53, 0.79, 0.56),
        dark: (0.12, 0.19, 0.25)
    )

    static let farmHillNear = farmTone(
        light: (0.44, 0.73, 0.44),
        dark: (0.10, 0.23, 0.23)
    )

    static let farmGrassLight = farmTone(
        light: (0.60, 0.83, 0.47),
        dark: (0.13, 0.24, 0.21)
    )

    static let farmGrassDeep = farmTone(
        light: (0.42, 0.71, 0.36),
        dark: (0.08, 0.16, 0.15)
    )

    static let farmGrassBlade = farmTone(
        light: (0.33, 0.61, 0.28),
        dark: (0.21, 0.37, 0.29)
    )

    static let farmBarn = farmTone(
        light: (0.82, 0.29, 0.25),
        dark: (0.50, 0.20, 0.19)
    )

    static let farmBarnRoof = farmTone(
        light: (0.39, 0.25, 0.20),
        dark: (0.24, 0.16, 0.14)
    )

    static let farmWood = farmTone(
        light: (0.76, 0.56, 0.35),
        dark: (0.42, 0.31, 0.21)
    )

    static let farmWoodDark = farmTone(
        light: (0.55, 0.38, 0.23),
        dark: (0.28, 0.20, 0.14)
    )

    static let farmTreeTop = farmTone(
        light: (0.32, 0.64, 0.37),
        dark: (0.14, 0.30, 0.23)
    )

    static let farmSun = farmTone(
        light: (1.0, 0.84, 0.34),
        dark: (0.93, 0.93, 0.86)
    )

    static let farmFlower = farmTone(
        light: (1.0, 0.93, 0.55),
        dark: (0.85, 0.80, 0.55)
    )

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
