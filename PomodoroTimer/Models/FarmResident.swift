import Foundation

enum GrowthStage: Int, CaseIterable, Identifiable {
    case newborn
    case young
    case grown
    case strong
    case legendary

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .newborn: return "Newborn"
        case .young: return "Young"
        case .grown: return "Grown"
        case .strong: return "Strong"
        case .legendary: return "Legendary"
        }
    }

    /// Completed sessions needed to reach this stage.
    var requiredSessions: Int {
        switch self {
        case .newborn: return 1
        case .young: return 3
        case .grown: return 8
        case .strong: return 18
        case .legendary: return 35
        }
    }

    var next: GrowthStage? {
        GrowthStage(rawValue: rawValue + 1)
    }

    static func stage(for sessions: Int) -> GrowthStage {
        allCases.last { sessions >= $0.requiredSessions } ?? .newborn
    }
}

struct FarmResident: Identifiable {
    let type: PetType
    let sessions: Int
    let totalFocus: TimeInterval
    let firstRaised: Date?
    let lastRaised: Date?
    let bestLikability: Int
    let raisedToday: Int

    var id: String { type.rawValue }

    var hasArrived: Bool { sessions > 0 }

    var stage: GrowthStage { GrowthStage.stage(for: sessions) }

    static let fullyGrownSessions = 35
    static let minScale: CGFloat = 0.55
    static let maxScale: CGFloat = 1.2

    /// Grows quickly at first so early sessions feel rewarding, then eases toward full size.
    var scale: CGFloat {
        guard sessions > 0 else { return Self.minScale }
        let capped = min(Double(sessions), Double(Self.fullyGrownSessions))
        let eased = (capped / Double(Self.fullyGrownSessions)).squareRoot()
        return Self.minScale + (Self.maxScale - Self.minScale) * CGFloat(eased)
    }

    var sizePercent: Int {
        Int((scale / Self.maxScale * 100).rounded())
    }

    var isFullyGrown: Bool {
        sessions >= Self.fullyGrownSessions
    }

    var sessionsToNextStage: Int? {
        guard let next = stage.next else { return nil }
        return max(0, next.requiredSessions - sessions)
    }

    var stageProgress: Double {
        guard hasArrived else { return 0 }
        guard let next = stage.next else { return 1 }
        let floorValue = stage.requiredSessions
        let span = next.requiredSessions - floorValue
        guard span > 0 else { return 1 }
        return min(1, max(0, Double(sessions - floorValue) / Double(span)))
    }
}
