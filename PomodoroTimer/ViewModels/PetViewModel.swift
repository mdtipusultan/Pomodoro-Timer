import Foundation
import SwiftData
import Observation

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
}
