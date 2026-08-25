import Foundation
import Observation
import SwiftData
import SwiftUI
import UIKit

@Observable
@MainActor
final class SettingsViewModel {
    var weekStartsOnMonday: Bool = false {
        didSet { UserDefaults.standard.set(weekStartsOnMonday, forKey: Keys.weekStartsOnMonday) }
    }

    var use24HourTime: Bool = false {
        didSet { UserDefaults.standard.set(use24HourTime, forKey: Keys.use24HourTime) }
    }

    var hapticsEnabled: Bool = true {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    var nightOwlMode: Bool = false {
        didSet { UserDefaults.standard.set(nightOwlMode, forKey: TimerService.Keys.nightOwlMode) }
    }

    var dailyReminderEnabled: Bool = false {
        didSet { UserDefaults.standard.set(dailyReminderEnabled, forKey: AppGroup.Keys.dailyReminderEnabled) }
    }

    var dailyReminderHour: Int = 9 {
        didSet { UserDefaults.standard.set(dailyReminderHour, forKey: AppGroup.Keys.dailyReminderHour) }
    }

    var dailyReminderMinute: Int = 0 {
        didSet { UserDefaults.standard.set(dailyReminderMinute, forKey: AppGroup.Keys.dailyReminderMinute) }
    }

    var missedDayReminderEnabled: Bool = false {
        didSet { UserDefaults.standard.set(missedDayReminderEnabled, forKey: MissedDayReminderService.Keys.enabled) }
    }

    var missedDayReminderHour: Int = MissedDayReminderService.defaultHour {
        didSet { UserDefaults.standard.set(missedDayReminderHour, forKey: MissedDayReminderService.Keys.hour) }
    }

    var missedDayReminderMinute: Int = MissedDayReminderService.defaultMinute {
        didSet { UserDefaults.standard.set(missedDayReminderMinute, forKey: MissedDayReminderService.Keys.minute) }
    }

    var themeSelection: String = "system" {
        didSet { UserDefaults.standard.set(themeSelection, forKey: Keys.themeSelection) }
    }

    var selectedAppIcon: String = "default" {
        didSet {
            UserDefaults.standard.set(selectedAppIcon, forKey: Keys.selectedAppIcon)
            AppIconService.apply(selection: selectedAppIcon)
        }
    }

    var colorScheme: ColorScheme? {
        switch themeSelection {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    init() {
        weekStartsOnMonday = UserDefaults.standard.bool(forKey: Keys.weekStartsOnMonday)
        use24HourTime = UserDefaults.standard.bool(forKey: Keys.use24HourTime)
        hapticsEnabled = UserDefaults.standard.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        nightOwlMode = UserDefaults.standard.bool(forKey: TimerService.Keys.nightOwlMode)
        dailyReminderEnabled = UserDefaults.standard.bool(forKey: AppGroup.Keys.dailyReminderEnabled)
        dailyReminderHour = UserDefaults.standard.object(forKey: AppGroup.Keys.dailyReminderHour) as? Int ?? 9
        dailyReminderMinute = UserDefaults.standard.object(forKey: AppGroup.Keys.dailyReminderMinute) as? Int ?? 0
        missedDayReminderEnabled = UserDefaults.standard.bool(forKey: MissedDayReminderService.Keys.enabled)
        missedDayReminderHour = UserDefaults.standard.object(forKey: MissedDayReminderService.Keys.hour) as? Int
            ?? MissedDayReminderService.defaultHour
        missedDayReminderMinute = UserDefaults.standard.object(forKey: MissedDayReminderService.Keys.minute) as? Int
            ?? MissedDayReminderService.defaultMinute
        themeSelection = UserDefaults.standard.string(forKey: Keys.themeSelection) ?? "system"
        selectedAppIcon = UserDefaults.standard.string(forKey: Keys.selectedAppIcon) ?? "default"
    }

    func applySavedAppIcon() {
        AppIconService.apply(selection: selectedAppIcon)
    }

    func applyMissedDayReminder(context: ModelContext) {
        guard missedDayReminderEnabled else {
            MissedDayReminderService.refresh(context: context)
            return
        }
        Task {
            _ = await NotificationService.shared.requestAuthorization()
            MissedDayReminderService.refresh(context: context)
        }
    }

    func applyDailyReminder() {
        if dailyReminderEnabled {
            Task {
                _ = await NotificationService.shared.requestAuthorization()
                NotificationService.shared.scheduleDailyReminder(at: dailyReminderHour, minute: dailyReminderMinute)
            }
        } else {
            NotificationService.shared.cancelDailyReminder()
        }
    }

    private enum Keys {
        static let weekStartsOnMonday = "weekStartsOnMonday"
        static let use24HourTime = "use24HourTime"
        static let hapticsEnabled = "hapticsEnabled"
        static let themeSelection = "themeSelection"
        static let selectedAppIcon = "selectedAppIcon"
    }
}
