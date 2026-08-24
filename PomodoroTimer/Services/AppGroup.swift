import Foundation

enum AppGroup {
    static let identifier = "group.com.office.PomodoroTimer"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    enum Keys {
        static let widgetSnapshot = "widgetSnapshot"
        static let unviewedPetCount = "unviewedPetCount"
        // FAMILY_CONTROLS_DISABLED
        // static let familyActivitySelection = "familyActivitySelection"
        static let pausedRemaining = "pausedRemaining"
        static let stateBeforePause = "stateBeforePause"
        static let dailyReminderEnabled = "dailyReminderEnabled"
        static let dailyReminderHour = "dailyReminderHour"
        static let dailyReminderMinute = "dailyReminderMinute"
        static let timerMode = "timerMode"
    }
}

struct WidgetSnapshot: Codable, Equatable {
    var todayMinutes: Int
    var streak: Int
    var weekHours: [Double]
    var sessionTitles: [String]
    var updatedAt: Date

    static let empty = WidgetSnapshot(
        todayMinutes: 0,
        streak: 0,
        weekHours: Array(repeating: 0, count: 7),
        sessionTitles: [],
        updatedAt: .now
    )
}
