import Foundation
import SwiftData

@MainActor
enum MissedDayReminderService {
    enum Keys {
        static let enabled = "missedDayReminderEnabled"
        static let hour = "missedDayReminderHour"
        static let minute = "missedDayReminderMinute"
    }

    static let defaultHour = 20
    static let defaultMinute = 0

    /// Recomputes today's focus state and re-queues the upcoming reminders.
    /// Safe to call often — it always clears the old requests first.
    static func refresh(context: ModelContext) {
        let defaults = UserDefaults.standard

        guard defaults.bool(forKey: Keys.enabled) else {
            NotificationService.shared.cancelMissedDayReminders()
            return
        }

        let nightOwl = defaults.bool(forKey: TimerService.Keys.nightOwlMode)
        let sessions = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        let focusDays = Set(
            sessions
                .filter(\.wasSuccessful)
                .map { $0.startDate.adjustedForNightOwl(nightOwlMode: nightOwl).startOfDay }
        )

        NotificationService.shared.scheduleMissedDayReminders(
            hour: defaults.object(forKey: Keys.hour) as? Int ?? defaultHour,
            minute: defaults.object(forKey: Keys.minute) as? Int ?? defaultMinute,
            hasFocusedToday: focusDays.contains(Date().startOfDay),
            streak: streak(from: focusDays)
        )
    }

    private static func streak(from focusDays: Set<Date>) -> Int {
        guard !focusDays.isEmpty else { return 0 }

        let calendar = Calendar.current
        var checkDate = Date().startOfDay

        if !focusDays.contains(checkDate) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        var streak = 0
        while focusDays.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }
}
