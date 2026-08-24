import Foundation
import SwiftData
import WidgetKit

enum WidgetDataStore {
    @MainActor
    static func refresh(sessions: [FocusSession], nightOwlMode: Bool, weekStartsOnMonday: Bool) {
        let today = Date().startOfDay
        let todayMinutes = Int(
            sessions
                .filter {
                    $0.wasSuccessful &&
                    $0.startDate.adjustedForNightOwl(nightOwlMode: nightOwlMode).startOfDay == today
                }
                .reduce(0) { $0 + $1.actualDuration } / 60
        )

        let successfulDays = Set(
            sessions
                .filter(\.wasSuccessful)
                .map { $0.startDate.adjustedForNightOwl(nightOwlMode: nightOwlMode).startOfDay }
        )
        var streak = 0
        var checkDate = today
        if !successfulDays.contains(checkDate) {
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        while successfulDays.contains(checkDate) {
            streak += 1
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        let calendar = Calendar.current
        var weekHours: [Double] = []
        let weekStart = Date.weekStart(for: Date(), startsOnMonday: weekStartsOnMonday)
        for offset in 0..<7 {
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            let total = sessions
                .filter {
                    $0.wasSuccessful &&
                    $0.startDate.adjustedForNightOwl(nightOwlMode: nightOwlMode).startOfDay == day.startOfDay
                }
                .reduce(0.0) { $0 + $1.actualDuration }
            weekHours.append(total / 3600)
        }

        let titles = sessions
            .filter {
                $0.wasSuccessful &&
                $0.startDate.adjustedForNightOwl(nightOwlMode: nightOwlMode).startOfDay == today
            }
            .prefix(5)
            .map { $0.tag?.name ?? "Focus" }

        let snapshot = WidgetSnapshot(
            todayMinutes: todayMinutes,
            streak: streak,
            weekHours: weekHours,
            sessionTitles: Array(titles),
            updatedAt: Date()
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            AppGroup.defaults.set(data, forKey: AppGroup.Keys.widgetSnapshot)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func loadSnapshot() -> WidgetSnapshot {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.Keys.widgetSnapshot),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}
