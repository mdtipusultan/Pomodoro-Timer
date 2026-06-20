import Foundation
import Observation
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
        themeSelection = UserDefaults.standard.string(forKey: Keys.themeSelection) ?? "system"
        selectedAppIcon = UserDefaults.standard.string(forKey: Keys.selectedAppIcon) ?? "default"
    }

    func applySavedAppIcon() {
        AppIconService.apply(selection: selectedAppIcon)
    }

    private enum Keys {
        static let weekStartsOnMonday = "weekStartsOnMonday"
        static let use24HourTime = "use24HourTime"
        static let hapticsEnabled = "hapticsEnabled"
        static let themeSelection = "themeSelection"
        static let selectedAppIcon = "selectedAppIcon"
    }
}
