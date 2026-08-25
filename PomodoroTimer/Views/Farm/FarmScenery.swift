import SwiftUI

// MARK: - Deterministic randomness

/// Xorshift generator so every animal keeps the same spot in the pasture
/// across launches. `Hashable.hashValue` is seeded per process and would
/// shuffle the farm on every cold start.
struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func unit() -> CGFloat {
        CGFloat(next() % 10_000) / 10_000
    }

    mutating func value(in range: ClosedRange<CGFloat>) -> CGFloat {
        range.lowerBound + unit() * (range.upperBound - range.lowerBound)
    }

    mutating func flag() -> Bool {
        next() % 2 == 0
    }
}

extension UUID {
    var stableSeed: UInt64 {
        let bytes = uuid
        let all: [UInt8] = [
            bytes.0, bytes.1, bytes.2, bytes.3,
            bytes.4, bytes.5, bytes.6, bytes.7,
            bytes.8, bytes.9, bytes.10, bytes.11,
            bytes.12, bytes.13, bytes.14, bytes.15
        ]
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in all {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }
}

// MARK: - Shapes

struct RoofShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Scenery pieces

struct FarmCloudView: View {
    var width: CGFloat = 64

    var body: some View {
        ZStack {
            Capsule()
                .frame(width: width, height: width * 0.34)
            Circle()
                .frame(width: width * 0.46, height: width * 0.46)
                .offset(x: -width * 0.20, y: -width * 0.13)
            Circle()
                .frame(width: width * 0.58, height: width * 0.58)
                .offset(x: width * 0.10, y: -width * 0.16)
        }
        .foregroundStyle(.white)
        .compositingGroup()
    }
}

struct FarmTreeView: View {
    var height: CGFloat = 60

    var body: some View {
        VStack(spacing: -height * 0.10) {
            ZStack {
                Circle()
                    .fill(Color.farmTreeTop)
                    .frame(width: height * 0.60, height: height * 0.60)
                    .offset(x: -height * 0.14, y: height * 0.06)
                Circle()
                    .fill(Color.farmTreeTop)
                    .frame(width: height * 0.56, height: height * 0.56)
                    .offset(x: height * 0.16, y: height * 0.08)
                Circle()
                    .fill(Color.farmTreeTop)
                    .frame(width: height * 0.68, height: height * 0.68)
                    .offset(y: -height * 0.06)
            }
            .compositingGroup()

            Capsule()
                .fill(Color.farmWoodDark)
                .frame(width: height * 0.13, height: height * 0.34)
        }
        .frame(height: height, alignment: .bottom)
    }
}

struct FarmBarnView: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            silo
            barn
        }
    }

    private var silo: some View {
        VStack(spacing: -7) {
            Ellipse()
                .fill(Color.farmBarnRoof)
                .frame(width: 28, height: 18)
            UnevenRoundedRectangle(bottomLeadingRadius: 3, bottomTrailingRadius: 3)
                .fill(Color.farmWood)
                .frame(width: 23, height: 46)
        }
    }

    private var barn: some View {
        VStack(spacing: -1) {
            RoofShape()
                .fill(Color.farmBarnRoof)
                .frame(width: 88, height: 30)

            ZStack(alignment: .bottom) {
                UnevenRoundedRectangle(bottomLeadingRadius: 4, bottomTrailingRadius: 4)
                    .fill(Color.farmBarn)
                    .frame(width: 72, height: 46)

                door
            }
        }
    }

    private var door: some View {
        ZStack {
            UnevenRoundedRectangle(topLeadingRadius: 13, topTrailingRadius: 13)
                .fill(Color.farmBarnRoof.opacity(0.82))
                .frame(width: 30, height: 32)

            Capsule()
                .fill(.white.opacity(0.55))
                .frame(width: 2.5, height: 34)
                .rotationEffect(.degrees(38))

            Capsule()
                .fill(.white.opacity(0.55))
                .frame(width: 2.5, height: 34)
                .rotationEffect(.degrees(-38))
        }
        .frame(width: 30, height: 32)
        .clipped()
    }
}

struct FarmFenceView: View {
    var postCount: Int = 9

    var body: some View {
        ZStack {
            VStack(spacing: 7) {
                rail
                rail
            }
            .padding(.top, 8)

            HStack(spacing: 0) {
                ForEach(0..<postCount, id: \.self) { index in
                    post
                    if index < postCount - 1 {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .frame(height: 30)
    }

    private var rail: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.farmWood)
            .frame(height: 5)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.white.opacity(0.16))
                    .frame(height: 1.5)
            }
    }

    private var post: some View {
        UnevenRoundedRectangle(topLeadingRadius: 3, topTrailingRadius: 3)
            .fill(Color.farmWoodDark)
            .frame(width: 6, height: 30)
    }
}

struct GrassBladeShape: Shape {
    var lean: CGFloat

    func path(in rect: CGRect) -> Path {
        let base = CGPoint(x: rect.midX, y: rect.maxY)
        let tip = CGPoint(x: rect.midX + rect.width * lean, y: rect.minY)
        let control = CGPoint(x: rect.midX + rect.width * lean * 0.15, y: rect.midY)

        var path = Path()
        path.move(to: CGPoint(x: base.x - rect.width * 0.16, y: base.y))
        path.addQuadCurve(to: tip, control: control)
        path.addQuadCurve(
            to: CGPoint(x: base.x + rect.width * 0.16, y: base.y),
            control: CGPoint(x: control.x + rect.width * 0.22, y: control.y)
        )
        path.closeSubpath()
        return path
    }
}

struct FarmGrassTuftView: View {
    var scale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .bottom) {
            blade(lean: -0.55, height: 9)
            blade(lean: 0.05, height: 13)
            blade(lean: 0.6, height: 8)
        }
        .frame(width: 17 * scale, height: 13 * scale, alignment: .bottom)
        .opacity(0.85)
    }

    private func blade(lean: CGFloat, height: CGFloat) -> some View {
        GrassBladeShape(lean: lean)
            .fill(Color.farmGrassBlade)
            .frame(width: 7 * scale, height: height * scale)
    }
}

struct FarmFlowerView: View {
    var scale: CGFloat = 1

    var body: some View {
        VStack(spacing: -1) {
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Ellipse()
                        .fill(Color.farmFlower)
                        .frame(width: 3.4 * scale, height: 6 * scale)
                        .offset(y: -2.4 * scale)
                        .rotationEffect(.degrees(Double(index) * 72))
                }
                Circle()
                    .fill(Color.appOrange)
                    .frame(width: 3 * scale, height: 3 * scale)
            }
            Capsule()
                .fill(Color.farmGrassBlade)
                .frame(width: 1.6 * scale, height: 7 * scale)
        }
        .frame(height: 16 * scale, alignment: .bottom)
    }
}

// MARK: - Sky band

struct FarmSkyView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var drifting = false

    private let bandHeight: CGFloat = 214
    private let groundStrip: CGFloat = 54

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [.farmSkyTop, .farmSkyBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            if colorScheme == .dark {
                starsLayer
            }

            celestialBody

            cloudsLayer

            hillsLayer

            Rectangle()
                .fill(Color.farmGrassLight)
                .frame(height: groundStrip)

            sceneryLayer

            FarmFenceView()
                .padding(.bottom, groundStrip - 24)
        }
        .frame(height: bandHeight)
        .clipped()
        .onAppear {
            guard !drifting else { return }
            withAnimation(.linear(duration: 34).repeatForever(autoreverses: true)) {
                drifting = true
            }
        }
    }

    private var celestialBody: some View {
        ZStack {
            Circle()
                .fill(Color.farmSun.opacity(0.28))
                .frame(width: 76, height: 76)
                .blur(radius: 12)
            Circle()
                .fill(Color.farmSun)
                .frame(width: 44, height: 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 22)
        .padding(.trailing, 30)
    }

    private var cloudsLayer: some View {
        ZStack {
            FarmCloudView(width: 70)
                .opacity(colorScheme == .dark ? 0.16 : 0.92)
                .offset(x: drifting ? 26 : -18, y: 30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 22)

            FarmCloudView(width: 50)
                .opacity(colorScheme == .dark ? 0.12 : 0.75)
                .offset(x: drifting ? -22 : 16, y: 66)
                .frame(maxWidth: .infinity, alignment: .center)

            FarmCloudView(width: 42)
                .opacity(colorScheme == .dark ? 0.10 : 0.6)
                .offset(x: drifting ? 14 : -12, y: 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 26)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var starsLayer: some View {
        ZStack {
            ForEach(FarmScenery.stars) { star in
                Circle()
                    .fill(.white)
                    .frame(width: star.size, height: star.size)
                    .opacity(star.opacity)
                    .offset(x: star.x, y: star.y)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // Hills are ellipses that sink below the grass line, so only the dome shows.
    private var hillsLayer: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.farmHillFar)
                .frame(width: 330, height: 124)
                .offset(x: -96)

            Ellipse()
                .fill(Color.farmHillNear)
                .frame(width: 270, height: 96)
                .offset(x: 104)
        }
        .padding(.bottom, groundStrip - 26)
    }

    private var sceneryLayer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            FarmTreeView(height: 64)
            FarmTreeView(height: 44)
            Spacer(minLength: 12)
            FarmBarnView()
        }
        .padding(.horizontal, 22)
        .padding(.bottom, groundStrip - 12)
    }
}

// MARK: - Static scenery data

enum FarmScenery {
    struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    static let stars: [Star] = {
        var generator = SeededGenerator(seed: 0x5EED_5741)
        return (0..<26).map { index in
            Star(
                id: index,
                x: generator.value(in: 12...360),
                y: generator.value(in: 8...110),
                size: generator.value(in: 1.4...3.0),
                opacity: Double(generator.value(in: 0.35...0.95))
            )
        }
    }()
}
