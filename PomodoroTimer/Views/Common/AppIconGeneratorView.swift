import SwiftUI

/// Renders the KittyFocus app icon for export to Assets.xcassets.
/// Open in Preview, export at 1024×1024, then generate smaller sizes in Xcode.
struct AppIconGeneratorView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.58, blue: 0.0),
                    Color(red: 1.0, green: 0.72, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "cat.fill")
                .font(.system(size: 520))
                .foregroundStyle(.white)

            Image(systemName: "timer")
                .font(.system(size: 180, weight: .bold))
                .foregroundStyle(.white)
                .offset(x: 280, y: 280)
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 220))
    }
}

#Preview {
    AppIconGeneratorView()
}
