import Foundation
import SwiftData
import Observation

struct FarmStats {
    var total: Int
    var today: Int
    var species: Int
    var level: Int
    var progress: Double
    var animalsToNextLevel: Int

    static let animalsPerLevel = 8

    static let empty = FarmStats(
        total: 0,
        today: 0,
        species: 0,
        level: 1,
        progress: 0,
        animalsToNextLevel: animalsPerLevel
    )
}

@Observable
@MainActor
final class PetViewModel {
    func petsSorted(_ pets: [Pet]) -> [Pet] {
        pets.sorted { $0.raisedDate > $1.raisedDate }
    }

    func session(for pet: Pet, sessions: [FocusSession]) -> FocusSession? {
        sessions.first { $0.id == pet.sessionId }
    }

    func updatePetName(_ pet: Pet, name: String, context: ModelContext) {
        pet.name = name.isEmpty ? nil : name
        try? context.save()
    }

    func stats(for pets: [Pet]) -> FarmStats {
        guard !pets.isEmpty else { return .empty }

        let perLevel = FarmStats.animalsPerLevel
        let total = pets.count
        let earnedInLevel = total % perLevel

        return FarmStats(
            total: total,
            today: pets.filter { Calendar.current.isDateInToday($0.raisedDate) }.count,
            species: Set(pets.map(\.typeRaw)).count,
            level: total / perLevel + 1,
            progress: Double(earnedInLevel) / Double(perLevel),
            animalsToNextLevel: perLevel - earnedInLevel
        )
    }
}
