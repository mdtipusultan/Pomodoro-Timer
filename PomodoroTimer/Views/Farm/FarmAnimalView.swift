import SwiftUI

struct FarmSpot {
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var flipped: Bool
    var bobDuration: Double
    var bobDelay: Double
}

enum FarmLayout {
    static let rowHeight: CGFloat = 112
    static let topInset: CGFloat = 30
    static let bottomInset: CGFloat = 24
    static let maxVisible = 48

    static func rows(count: Int, columns: Int) -> Int {
        max(2, Int(ceil(Double(max(count, 1)) / Double(columns))))
    }

    static func height(count: Int, columns: Int) -> CGFloat {
        topInset + CGFloat(rows(count: count, columns: columns)) * rowHeight + bottomInset
    }

    static func spot(index: Int, seed: UUID, columns: Int) -> FarmSpot {
        var generator = SeededGenerator(seed: seed.stableSeed)
        let row = index / columns
        let column = index % columns
        let slot = (CGFloat(column) + 0.5) / CGFloat(columns)
        let drift = generator.value(in: -0.05...0.05)

        return FarmSpot(
            x: min(max(slot + drift, 0.12), 0.88),
            y: topInset + CGFloat(row) * rowHeight + rowHeight / 2 + generator.value(in: -11...11),
            scale: generator.value(in: 0.90...1.10),
            flipped: generator.flag(),
            bobDuration: Double(generator.value(in: 1.7...2.7)),
            bobDelay: Double(generator.value(in: 0...1.3))
        )
    }

    struct Decoration: Identifiable {
        enum Kind {
            case grass, flower, stone
        }

        let id: Int
        let x: CGFloat
        let y: CGFloat
        let scale: CGFloat
        let kind: Kind
    }

    static func decorations(rows: Int) -> [Decoration] {
        var generator = SeededGenerator(seed: 0xDEC0_2A71)
        let count = max(8, rows * 5)

        return (0..<count).map { index in
            let roll = generator.next() % 10
            let kind: Decoration.Kind = roll < 6 ? .grass : (roll < 9 ? .flower : .stone)
            return Decoration(
                id: index,
                x: generator.value(in: 0.05...0.95),
                y: generator.value(in: 0.02...0.98),
                scale: generator.value(in: 0.75...1.25),
                kind: kind
            )
        }
    }
}

struct FarmAnimalView: View {
    let pet: Pet
    let spot: FarmSpot
    let isNew: Bool
    let entranceDelay: Double
    let onTap: () -> Void

    @State private var bobbing = false
    @State private var appeared = false

    private let size: CGFloat = 74

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                ZStack(alignment: .bottom) {
                    Ellipse()
                        .fill(Color.farmGrassDeep.opacity(0.42))
                        .frame(width: size * 0.46, height: 9)
                        .blur(radius: 2.5)
                        .scaleEffect(x: bobbing ? 0.88 : 1, y: bobbing ? 0.82 : 1)

                    if isNew {
                        Circle()
                            .fill(Color.appOrange.opacity(0.30))
                            .frame(width: size * 0.86, height: size * 0.86)
                            .blur(radius: 12)
                            .offset(y: -size * 0.34)
                    }

                    Image(pet.type.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .scaleEffect(x: spot.flipped ? -1 : 1)
                        .offset(y: bobbing ? -7 : -2)
                }
                .frame(width: size, height: size + 8, alignment: .bottom)

                if let name = pet.name, !name.isEmpty {
                    Text(name)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.farmWoodDark.opacity(0.85), in: Capsule())
                }
            }
        }
        .buttonStyle(FarmAnimalButtonStyle())
        .scaleEffect(appeared ? spot.scale : spot.scale * 0.55)
        .opacity(appeared ? 1 : 0)
        .accessibilityLabel("\(pet.name ?? pet.type.displayName), raised on \(pet.raisedDate.formattedShortDate())")
        .accessibilityHint("Double tap to view details")
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.48, dampingFraction: 0.68).delay(entranceDelay)) {
                appeared = true
            }
            withAnimation(
                .easeInOut(duration: spot.bobDuration)
                .repeatForever(autoreverses: true)
                .delay(spot.bobDelay)
            ) {
                bobbing = true
            }
        }
    }
}

struct FarmAnimalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.12 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
