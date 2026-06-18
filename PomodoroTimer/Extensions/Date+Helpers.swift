import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func adjustedForNightOwl(nightOwlMode: Bool) -> Date {
        guard nightOwlMode else { return self }
        let hour = Calendar.current.component(.hour, from: self)
        if hour >= 0 && hour < 4 {
            return Calendar.current.date(byAdding: .day, value: -1, to: self) ?? self
        }
        return self
    }

    static func weekStart(for date: Date, startsOnMonday: Bool) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = startsOnMonday ? 2 : 1
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date.startOfDay
    }

    func formattedTime(use24Hour: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: self)
    }

    func formattedShortDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

extension TimeInterval {
    var formattedTimer: String {
        let total = max(0, Int(self))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedHoursMinutes: String {
        let total = max(0, Int(self))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
