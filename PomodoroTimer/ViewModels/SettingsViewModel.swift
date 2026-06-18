import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    var focusMinutes: Int {
        get { Int(UserDefaults.standard.double(forKey: TimerService.Keys.focusDuration).nonZeroOr(25 * 60) / 60) }
        set { UserDefaults.standard.set(TimeInterval(newValue * 60), forKey: TimerService.Keys.focusDuration) }
    }

    var shortBreakMinutes: Int {
        get { Int(UserDefaults.standard.double(forKey: TimerService.Keys.shortBreakDuration).nonZeroOr(300) / 60) }
        set { UserDefaults.standard.set(TimeInterval(newValue * 60), forKey: TimerService.Keys.shortBreakDuration) }
    }

    var longBreakMinutes: Int {
        get { Int(UserDefaults.standard.double(forKey: TimerService.Keys.longBreakDuration).nonZeroOr(900) / 60) }
        set { UserDefaults.standard.set(TimeInterval(newValue * 60), forKey: TimerService.Keys.longBreakDuration) }
    }

    var cyclesBeforeLongBreak: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: TimerService.Keys.cyclesBeforeLongBreak)
            return v > 0 ? v : 4
        }
        set { UserDefaults.standard.set(newValue, forKey: TimerService.Keys.cyclesBeforeLongBreak) }
    }

    var autoStartBreaks: Bool {
        get { UserDefaults.standard.bool(forKey: TimerService.Keys.autoStartBreaks) }
        set { UserDefaults.standard.set(newValue, forKey: TimerService.Keys.autoStartBreaks) }
    }

    var nightOwlMode: Bool {
        get { UserDefaults.standard.bool(forKey: TimerService.Keys.nightOwlMode) }
        set { UserDefaults.standard.set(newValue, forKey: TimerService.Keys.nightOwlMode) }
    }

    var weekStartsOnMonday: Bool {
        get { UserDefaults.standard.bool(forKey: "weekStartsOnMonday") }
        set { UserDefaults.standard.set(newValue, forKey: "weekStartsOnMonday") }
    }

    var use24HourTime: Bool {
        get { UserDefaults.standard.bool(forKey: "use24HourTime") }
        set { UserDefaults.standard.set(newValue, forKey: "use24HourTime") }
    }

    var hapticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "hapticsEnabled") }
    }

    var themeSelection: String {
        get { UserDefaults.standard.string(forKey: "themeSelection") ?? "system" }
        set { UserDefaults.standard.set(newValue, forKey: "themeSelection") }
    }

    var selectedAppIcon: String {
        get { UserDefaults.standard.string(forKey: "selectedAppIcon") ?? "default" }
        set { UserDefaults.standard.set(newValue, forKey: "selectedAppIcon") }
    }

    var colorScheme: ColorScheme? {
        switch themeSelection {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
}

private extension Double {
    func nonZeroOr(_ fallback: Double) -> Double {
        self > 0 ? self : fallback
    }
}
