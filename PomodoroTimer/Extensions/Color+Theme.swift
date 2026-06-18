import SwiftUI

extension Color {
    static let appOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let appBackground = Color(red: 1.0, green: 0.97, blue: 0.94)
    static let appSurface = Color.white
    static let appSecondary = Color(red: 0.55, green: 0.55, blue: 0.57)
    static let breakGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let dangerRed = Color(red: 1.0, green: 0.23, blue: 0.19)

    static let timerFocus = appOrange
    static let timerBreak = breakGreen
    static let petAlive = appOrange
    static let petDead = appSecondary

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
