import SwiftUI

struct FarmResidentView: View {
    let resident: FarmResident
    let name: String
    let onTap: () -> Void

    @State private var bobbing = false
    @State private var appeared = false

    /// Size of a fully grown companion. Everything scales down from here.
    private let baseSize: CGFloat = 104

    private var imageSize: CGFloat {
        baseSize * resident.scale
    }

    private var isNew: Bool {
        resident.raisedToday > 0
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Spacer(minLength: 0)

                ZStack(alignment: .bottom) {
                    FarmGrassTuftView(scale: 0.9)
                        .offset(x: -imageSize * 0.46, y: 1)

                    FarmGrassTuftView(scale: 0.7)
                        .offset(x: imageSize * 0.44, y: 1)

                    if resident.hasArrived {
                        FarmFlowerView(scale: 0.85)
                            .offset(x: imageSize * 0.6, y: 1)
                    }

                    Ellipse()
                        .fill(Color.farmGrassDeep.opacity(0.4))
                        .frame(width: imageSize * 0.52, height: 10)
                        .blur(radius: 2.5)
                        .scaleEffect(x: bobbing ? 0.9 : 1, y: bobbing ? 0.84 : 1)

                    if isNew {
                        Circle()
                            .fill(Color.appOrange.opacity(0.32))
                            .frame(width: imageSize * 0.9, height: imageSize * 0.9)
                            .blur(radius: 14)
                            .offset(y: -imageSize * 0.36)
                    }

                    Image(resident.type.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize, height: imageSize)
                        .opacity(resident.hasArrived ? 1 : 0.2)
                        .grayscale(resident.hasArrived ? 0 : 1)
                        .offset(y: bobbing ? -6 : -1)
                }
                .frame(height: baseSize * FarmResident.maxScale * 0.86, alignment: .bottom)

                caption
            }
        }
        .buttonStyle(FarmResidentButtonStyle())
        .scaleEffect(appeared ? 1 : 0.7)
        .opacity(appeared ? 1 : 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Double tap for statistics")
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
            guard resident.hasArrived else { return }
            withAnimation(
                .easeInOut(duration: bobDuration)
                .repeatForever(autoreverses: true)
                .delay(bobDelay)
            ) {
                bobbing = true
            }
        }
    }

    private var caption: some View {
        VStack(spacing: 3) {
            Text(resident.hasArrived ? name : resident.type.displayName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            if resident.hasArrived {
                Text("\(resident.stage.title) · \(resident.sessions)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.farmWoodDark.opacity(0.82), in: Capsule())
            } else {
                Text("Not raised yet")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
    }

    private var accessibilityText: String {
        guard resident.hasArrived else {
            return "\(resident.type.displayName), not raised yet"
        }
        return "\(name), \(resident.stage.title), \(resident.sessions) sessions, \(resident.sizePercent) percent grown"
    }

    private var bobDuration: Double {
        var generator = SeededGenerator(seed: resident.type.rawValue.stableSeed)
        return Double(generator.value(in: 1.8...2.8))
    }

    private var bobDelay: Double {
        Double(resident.type.rawValue.count % 5) * 0.22
    }
}

struct FarmResidentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.08 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
