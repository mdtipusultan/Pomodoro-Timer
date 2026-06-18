import Foundation
import SwiftData

@Model
nonisolated final class Tag {
    var id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int
    @Relationship(deleteRule: .nullify, inverse: \FocusSession.tag)
    var sessions: [FocusSession]

    init(id: UUID = UUID(), name: String, colorHex: String, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.sessions = []
    }
}

extension Tag {
    static let defaultTags: [(String, String)] = [
        ("Work", "FF9500"),
        ("Study", "5856D6"),
        ("Personal", "34C759"),
        ("Creative", "FF2D55")
    ]
}
