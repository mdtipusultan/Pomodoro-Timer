import Foundation
import SwiftData

@Model
nonisolated final class Pet {
    var id: UUID
    var typeRaw: String
    var name: String?
    var raisedDate: Date
    var sessionId: UUID
    var likability: Int

    init(
        id: UUID = UUID(),
        type: PetType = .cat,
        name: String? = nil,
        raisedDate: Date = Date(),
        sessionId: UUID,
        likability: Int = 50
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.name = name
        self.raisedDate = raisedDate
        self.sessionId = sessionId
        self.likability = likability
    }
}

extension Pet {
    var type: PetType {
        PetType(rawValue: typeRaw) ?? .cat
    }
}
