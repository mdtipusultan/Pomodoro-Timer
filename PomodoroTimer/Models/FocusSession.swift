import Foundation
import SwiftData

@Model
nonisolated final class FocusSession {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var duration: TimeInterval
    var actualDuration: TimeInterval
    var isCompleted: Bool
    var isFailed: Bool
    var tag: Tag?
    var note: String?
    var isManuallyAdded: Bool

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        duration: TimeInterval,
        actualDuration: TimeInterval = 0,
        isCompleted: Bool = false,
        isFailed: Bool = false,
        tag: Tag? = nil,
        note: String? = nil,
        isManuallyAdded: Bool = false
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.actualDuration = actualDuration
        self.isCompleted = isCompleted
        self.isFailed = isFailed
        self.tag = tag
        self.note = note
        self.isManuallyAdded = isManuallyAdded
    }
}

extension FocusSession {
    var wasSuccessful: Bool {
        isCompleted && !isFailed
    }
}
