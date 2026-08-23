import SwiftUI

enum AppRadius {
    static let card: CGFloat = 20
    static let compact: CGFloat = 14
}

extension View {
    func appScreenBackground() -> some View {
        background(Color.appBackground.ignoresSafeArea())
    }

    func appCardStyle(radius: CGFloat = AppRadius.card) -> some View {
        background(Color.appSurface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.appShadow, radius: 8, x: 0, y: 3)
    }

    func appThemedList() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.appBackground)
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    var color: Color = .appOrange

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(color.gradient, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    var tint: Color = .primary
    var fill: Color = .appFill

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(tint)
            .background(fill, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
