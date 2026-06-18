import Foundation
import Observation

@Observable
final class AppState {
    var selectedPetType: PetType = .cat
    var unviewedPetCount: Int = 0
    var showPaywall: Bool = false
    var petAnimationState: PetAnimationState = .idle

    enum PetAnimationState {
        case idle, focusing, breakTime, success, failed
    }

    func markPetsViewed() {
        unviewedPetCount = 0
    }

    func incrementUnviewedPets() {
        unviewedPetCount += 1
    }
}
