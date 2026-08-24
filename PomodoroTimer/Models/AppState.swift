import Foundation
import Observation

@Observable
final class AppState {
    var selectedPetType: PetType = .cat
    var unviewedPetCount: Int {
        didSet { AppGroup.defaults.set(unviewedPetCount, forKey: AppGroup.Keys.unviewedPetCount) }
    }
    var showPaywall: Bool = false
    var petAnimationState: PetAnimationState = .idle

    enum PetAnimationState {
        case idle, focusing, breakTime, success, failed
    }

    init() {
        unviewedPetCount = AppGroup.defaults.integer(forKey: AppGroup.Keys.unviewedPetCount)
    }

    func markPetsViewed() {
        unviewedPetCount = 0
    }

    func incrementUnviewedPets() {
        unviewedPetCount += 1
    }
}
