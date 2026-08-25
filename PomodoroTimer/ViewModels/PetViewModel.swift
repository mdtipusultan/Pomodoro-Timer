import Foundation
import SwiftData
import Observation

struct FarmStats {
    var arrived: Int
    var today: Int
    var totalSessions: Int
    var level: Int
    var progress: Double
    var sessionsToNextLevel: Int

    static let sessionsPerLevel = 8

    static let empty = FarmStats(
        arrived: 0,
        today: 0,
        totalSessions: 0,
        level: 1,
        progress: 0,
        sessionsToNextLevel: sessionsPerLevel
    )
}

@Observable
@MainActor
final class PetViewModel {
    /// Companion names are per species now that the farm shows one animal of each kind.
    private(set) var speciesNames: [String: String] = [:]

    init() {
        for type in PetType.allCases {
            if let stored = UserDefaults.standard.string(forKey: Self.nameKey(for: type)) {
                speciesNames[type.rawValue] = stored
            }
        }
    }

    func name(for type: PetType) -> String {
        speciesNames[type.rawValue] ?? type.displayName
    }

    func hasCustomName(for type: PetType) -> Bool {
        speciesNames[type.rawValue] != nil
    }

    func setName(_ name: String, for type: PetType) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == type.displayName {
            speciesNames[type.rawValue] = nil
            UserDefaults.standard.removeObject(forKey: Self.nameKey(for: type))
        } else {
            speciesNames[type.rawValue] = trimmed
            UserDefaults.standard.set(trimmed, forKey: Self.nameKey(for: type))
        }
    }

    func residents(pets: [Pet], sessions: [FocusSession]) -> [FarmResident] {
        let durations = Dictionary(
            sessions.map { ($0.id, $0.actualDuration) },
            uniquingKeysWith: { first, _ in first }
        )
        let grouped = Dictionary(grouping: pets) { $0.type }

        return PetType.allCases.map { type in
            let group = grouped[type] ?? []
            return FarmResident(
                type: type,
                sessions: group.count,
                totalFocus: group.reduce(0) { $0 + (durations[$1.sessionId] ?? 0) },
                firstRaised: group.map(\.raisedDate).min(),
                lastRaised: group.map(\.raisedDate).max(),
                bestLikability: group.map(\.likability).max() ?? 0,
                raisedToday: group.filter { Calendar.current.isDateInToday($0.raisedDate) }.count
            )
        }
    }

    func stats(for residents: [FarmResident]) -> FarmStats {
        let total = residents.reduce(0) { $0 + $1.sessions }
        guard total > 0 else { return .empty }

        let perLevel = FarmStats.sessionsPerLevel
        let earnedInLevel = total % perLevel

        return FarmStats(
            arrived: residents.filter(\.hasArrived).count,
            today: residents.reduce(0) { $0 + $1.raisedToday },
            totalSessions: total,
            level: total / perLevel + 1,
            progress: Double(earnedInLevel) / Double(perLevel),
            sessionsToNextLevel: perLevel - earnedInLevel
        )
    }

    private static func nameKey(for type: PetType) -> String {
        "companionName.\(type.rawValue)"
    }
}
