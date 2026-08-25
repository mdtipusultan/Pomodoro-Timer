import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleSessionEnd(in seconds: TimeInterval, isBreak: Bool) {
        cancelPendingNotifications()

        let content = UNMutableNotificationContent()
        content.title = isBreak ? "Break's over!" : "Session complete! 🎉"
        content.body = isBreak ? "Ready to focus again?" : "Your kitty grew into a big cat today."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: "session-end",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDailyReminder(at hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to focus with \(AppBrand.name)! 🐱"
        content.body = "Your companion is waiting for you."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// iOS can't evaluate conditions at fire time, so a reminder is queued for each of the
    /// next few days and re-scheduled whenever the app is opened or a session completes.
    func scheduleMissedDayReminders(hour: Int, minute: Int, hasFocusedToday: Bool, streak: Int) {
        cancelMissedDayReminders()

        let calendar = Calendar.current
        let now = Date()

        for offset in 0..<Self.missedDayLookahead {
            if offset == 0 && hasFocusedToday { continue }

            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = hour
            components.minute = minute

            guard let fireDate = calendar.date(from: components), fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Your farm misses you 🐾"
            content.body = missedDayBody(streak: streak, isToday: offset == 0)
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                repeats: false
            )

            UNUserNotificationCenter.current().add(
                UNNotificationRequest(
                    identifier: Self.missedDayIdentifier(offset),
                    content: content,
                    trigger: trigger
                )
            )
        }
    }

    func cancelMissedDayReminders() {
        let identifiers = (0..<Self.missedDayLookahead).map(Self.missedDayIdentifier)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["session-end"])
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
    }

    private func missedDayBody(streak: Int, isToday: Bool) -> String {
        if isToday && streak > 0 {
            return "You're on a \(streak)-day streak. One session keeps it alive and your companion growing."
        }
        return "No focus session yet today. One session is all it takes to help your companion grow."
    }

    private static let missedDayLookahead = 7

    private static func missedDayIdentifier(_ offset: Int) -> String {
        "missed-day-reminder-\(offset)"
    }
}
