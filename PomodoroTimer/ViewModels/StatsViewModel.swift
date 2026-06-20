import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class StatsViewModel {
    enum ChartPeriod: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }

    var selectedPeriod: ChartPeriod = .week
    var nightOwlMode: Bool = false
    var weekStartsOnMonday: Bool = false

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let label: String
        let hours: Double
        let date: Date
    }

    struct DayGroup: Identifiable {
        let id = UUID()
        let date: Date
        let sessions: [FocusSession]
    }

    func filteredSessions(_ sessions: [FocusSession], isPro: Bool) -> [FocusSession] {
        let sorted = sessions.sorted { $0.startDate > $1.startDate }
        guard !isPro else { return sorted }
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sorted.filter { $0.startDate >= cutoff }
    }

    func todayFocusTime(_ sessions: [FocusSession]) -> TimeInterval {
        let today = Date().startOfDay
        return sessions
            .filter {
                $0.wasSuccessful &&
                $0.startDate.adjustedForNightOwl(nightOwlMode: nightOwlMode).startOfDay == today
            }
            .reduce(0) { $0 + $1.actualDuration }
    }

    func weekFocusTime(_ sessions: [FocusSession]) -> TimeInterval {
        let weekStart = Date.weekStart(for: Date(), startsOnMonday: weekStartsOnMonday)
        return sessions
            .filter { $0.wasSuccessful && $0.startDate >= weekStart }
            .reduce(0) { $0 + $1.actualDuration }
    }

    func currentStreak(_ sessions: [FocusSession]) -> Int {
        let successfulDays = Set(
            sessions
                .filter(\.wasSuccessful)
                .map { $0.startDate.adjustedForNightOwl(nightOwlMode: nightOwlMode).startOfDay }
        )
        guard !successfulDays.isEmpty else { return 0 }

        var streak = 0
        var checkDate = Date().startOfDay
        let calendar = Calendar.current

        if !successfulDays.contains(checkDate) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        while successfulDays.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    func totalCompletedSessions(_ sessions: [FocusSession]) -> Int {
        sessions.filter(\.wasSuccessful).count
    }

    func chartData(from sessions: [FocusSession], isPro: Bool) -> [ChartDataPoint] {
        let visible = filteredSessions(sessions.filter(\.wasSuccessful), isPro: isPro)
        switch selectedPeriod {
        case .day:
            return hourlyChartData(visible)
        case .week:
            return dailyChartData(visible, days: 7)
        case .month:
            return dailyChartData(visible, days: 30)
        }
    }

    func groupedSessions(_ sessions: [FocusSession], isPro: Bool) -> [DayGroup] {
        let filtered = filteredSessions(sessions, isPro: isPro)
        let grouped = Dictionary(grouping: filtered) { session in
            session.startDate.adjustedForNightOwl(nightOwlMode: nightOwlMode).startOfDay
        }
        return grouped
            .map { DayGroup(date: $0.key, sessions: $0.value.sorted { $0.startDate > $1.startDate }) }
            .sorted { $0.date > $1.date }
    }

    func deleteSession(_ session: FocusSession, context: ModelContext) {
        context.delete(session)
        try? context.save()
    }

    func addManualSession(
        startDate: Date,
        duration: TimeInterval,
        tag: Tag?,
        note: String?,
        context: ModelContext
    ) {
        let session = FocusSession(
            startDate: startDate,
            endDate: startDate.addingTimeInterval(duration),
            duration: duration,
            actualDuration: duration,
            isCompleted: true,
            isFailed: false,
            tag: tag,
            note: note,
            isManuallyAdded: true
        )
        context.insert(session)
        try? context.save()
    }

    private func hourlyChartData(_ sessions: [FocusSession]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let today = Date().startOfDay
        return (0..<24).map { hour in
            let hourStart = calendar.date(byAdding: .hour, value: hour, to: today) ?? today
            let total = sessions
                .filter { calendar.component(.hour, from: $0.startDate) == hour && $0.startDate.isSameDay(as: today) }
                .reduce(0.0) { $0 + $1.actualDuration }
            return ChartDataPoint(
                label: String(format: "%02d", hour),
                hours: total / 3600,
                date: hourStart
            )
        }
    }

    private func dailyChartData(_ sessions: [FocusSession], days: Int) -> [ChartDataPoint] {
        let calendar = Calendar.current
        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date().startOfDay) ?? Date()
            let total = sessions
                .filter { $0.startDate.adjustedForNightOwl(nightOwlMode: nightOwlMode).startOfDay == date }
                .reduce(0.0) { $0 + $1.actualDuration }
            let formatter = DateFormatter()
            formatter.dateFormat = days > 7 ? "M/d" : "EEE"
            return ChartDataPoint(
                label: formatter.string(from: date),
                hours: total / 3600,
                date: date
            )
        }
    }
}
