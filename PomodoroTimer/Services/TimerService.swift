import Foundation
import Observation

@Observable
@MainActor
final class TimerService {
    enum TimerState: String {
        case idle, focusing, shortBreak, longBreak, paused
    }

    enum TimerMode {
        case pomodoro, countdown
    }

    var state: TimerState = .idle
    var mode: TimerMode = .pomodoro
    var timeRemaining: TimeInterval = 25 * 60
    var totalDuration: TimeInterval = 25 * 60
    var currentCycle: Int = 0

    var focusDuration: TimeInterval = 25 * 60 {
        didSet {
            UserDefaults.standard.set(focusDuration, forKey: Keys.focusDuration)
            reloadSettings()
        }
    }

    var shortBreakDuration: TimeInterval = 5 * 60 {
        didSet { UserDefaults.standard.set(shortBreakDuration, forKey: Keys.shortBreakDuration) }
    }

    var longBreakDuration: TimeInterval = 15 * 60 {
        didSet { UserDefaults.standard.set(longBreakDuration, forKey: Keys.longBreakDuration) }
    }

    var cyclesBeforeLongBreak: Int = 4 {
        didSet { UserDefaults.standard.set(cyclesBeforeLongBreak, forKey: Keys.cyclesBeforeLongBreak) }
    }

    var autoStartBreaks: Bool = false {
        didSet { UserDefaults.standard.set(autoStartBreaks, forKey: Keys.autoStartBreaks) }
    }

    var nightOwlMode: Bool = false {
        didSet { UserDefaults.standard.set(nightOwlMode, forKey: Keys.nightOwlMode) }
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1 - (timeRemaining / totalDuration)
    }

    var sessionStartDate: Date?
    var lastCompletedFocusStartDate: Date?
    var pausedAtDate: Date?
    var accumulatedPausedTime: TimeInterval = 0

    var canCancelWithoutPenalty: Bool {
        guard let start = sessionStartDate else { return true }
        return Date().timeIntervalSince(start) < 10
    }

    var isRunning: Bool {
        state == .focusing || state == .shortBreak || state == .longBreak
    }

    var isOnBreak: Bool {
        state == .shortBreak || state == .longBreak
    }

    var stateLabel: String {
        switch state {
        case .idle: return "Ready"
        case .focusing: return "Focusing"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        case .paused: return "Paused"
        }
    }

    var ringColor: String {
        isOnBreak ? "break" : "focus"
    }

    private(set) var lastCompletedPhase: TimerState?
    private(set) var phaseCompletionCount: Int = 0

    private var tickTask: Task<Void, Never>?
    private var endDate: Date?

    enum Keys {
        static let focusDuration = "focusDuration"
        static let shortBreakDuration = "shortBreakDuration"
        static let longBreakDuration = "longBreakDuration"
        static let cyclesBeforeLongBreak = "cyclesBeforeLongBreak"
        static let autoStartBreaks = "autoStartBreaks"
        static let nightOwlMode = "nightOwlMode"
        static let sessionStartDate = "timerSessionStartDate"
        static let timerState = "timerState"
        static let timerEndDate = "timerEndDate"
        static let timerTotalDuration = "timerTotalDuration"
        static let timerCurrentCycle = "timerCurrentCycle"
    }

    init() {
        focusDuration = UserDefaults.standard.double(forKey: Keys.focusDuration).nonZeroOr(25 * 60)
        shortBreakDuration = UserDefaults.standard.double(forKey: Keys.shortBreakDuration).nonZeroOr(5 * 60)
        longBreakDuration = UserDefaults.standard.double(forKey: Keys.longBreakDuration).nonZeroOr(15 * 60)
        let savedCycles = UserDefaults.standard.integer(forKey: Keys.cyclesBeforeLongBreak)
        cyclesBeforeLongBreak = savedCycles > 0 ? savedCycles : 4
        autoStartBreaks = UserDefaults.standard.bool(forKey: Keys.autoStartBreaks)
        nightOwlMode = UserDefaults.standard.bool(forKey: Keys.nightOwlMode)
        reloadSettings()
        restoreFromPersistence()
    }

    func clearLastCompletedFocusStartDate() {
        lastCompletedFocusStartDate = nil
    }

    func reloadSettings() {
        if state == .idle {
            timeRemaining = focusDuration
            totalDuration = focusDuration
        }
    }

    func start() {
        guard state == .idle || state == .paused else { return }

        if state == .paused {
            resumeFromPause()
            return
        }

        if state == .idle {
            state = .focusing
            totalDuration = focusDuration
            timeRemaining = focusDuration
            currentCycle = 0
        }

        sessionStartDate = Date()
        endDate = Date().addingTimeInterval(timeRemaining)
        persistState()
        startTicking()
    }

    func startBreak(isLong: Bool) {
        state = isLong ? .longBreak : .shortBreak
        totalDuration = isLong ? longBreakDuration : shortBreakDuration
        timeRemaining = totalDuration
        sessionStartDate = Date()
        endDate = Date().addingTimeInterval(timeRemaining)
        persistState()
        startTicking()
    }

    func pause() {
        guard isRunning else { return }
        pausedAtDate = Date()
        state = .paused
        tickTask?.cancel()
        tickTask = nil
        persistState()
    }

    private func resumeFromPause() {
        guard let pausedAt = pausedAtDate else { return }
        accumulatedPausedTime += Date().timeIntervalSince(pausedAt)
        pausedAtDate = nil

        if state == .paused {
            state = previousRunningState()
        }

        endDate = Date().addingTimeInterval(timeRemaining)
        persistState()
        startTicking()
    }

    private func previousRunningState() -> TimerState {
        if currentCycle > 0 && timeRemaining <= shortBreakDuration {
            let completedCycles = currentCycle
            if completedCycles % cyclesBeforeLongBreak == 0 {
                return .longBreak
            }
            return .shortBreak
        }
        return .focusing
    }

    func stop(forced: Bool = false) {
        tickTask?.cancel()
        tickTask = nil
        clearPersistence()

        if !forced && canCancelWithoutPenalty {
            resetToIdle()
            return
        }

        resetToIdle()
    }

    func skipToBreak() {
        guard state == .shortBreak || state == .longBreak else { return }
        completeCurrentPhase()
    }

    func skipBreak() {
        guard isOnBreak else { return }
        tickTask?.cancel()
        tickTask = nil
        state = .idle
        timeRemaining = focusDuration
        totalDuration = focusDuration
        clearPersistence()
    }

    func completeCurrentPhase() {
        tickTask?.cancel()
        tickTask = nil

        let completedPhase = state

        switch state {
        case .focusing:
            lastCompletedFocusStartDate = sessionStartDate
            currentCycle += 1
            let isLongBreak = currentCycle % cyclesBeforeLongBreak == 0
            if autoStartBreaks {
                startBreak(isLong: isLongBreak)
            } else {
                state = isLongBreak ? .longBreak : .shortBreak
                totalDuration = isLongBreak ? longBreakDuration : shortBreakDuration
                timeRemaining = totalDuration
                sessionStartDate = nil
                endDate = nil
                clearPersistence()
            }
        case .shortBreak, .longBreak:
            state = .idle
            timeRemaining = focusDuration
            totalDuration = focusDuration
            sessionStartDate = nil
            endDate = nil
            clearPersistence()
        default:
            return
        }

        lastCompletedPhase = completedPhase
        phaseCompletionCount += 1
    }

    func tick() {
        recalculateFromDates()
        if timeRemaining <= 0 {
            timeRemaining = 0
            completeCurrentPhase()
        }
    }

    func recalculateFromDates() {
        guard let end = endDate else { return }
        timeRemaining = max(0, end.timeIntervalSinceNow)
    }

    func handleForeground() {
        guard isRunning || state == .paused else { return }
        recalculateFromDates()
        if timeRemaining <= 0 && isRunning {
            completeCurrentPhase()
        } else if isRunning {
            startTicking()
        }
    }

    func handleBackground() {
        persistState()
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                await self?.tick()
            }
        }
    }

    private func resetToIdle() {
        state = .idle
        timeRemaining = focusDuration
        totalDuration = focusDuration
        sessionStartDate = nil
        endDate = nil
        pausedAtDate = nil
        accumulatedPausedTime = 0
        currentCycle = 0
    }

    private func persistState() {
        UserDefaults.standard.set(sessionStartDate?.timeIntervalSince1970, forKey: Keys.sessionStartDate)
        UserDefaults.standard.set(endDate?.timeIntervalSince1970, forKey: Keys.timerEndDate)
        UserDefaults.standard.set(state.rawValue, forKey: Keys.timerState)
        UserDefaults.standard.set(totalDuration, forKey: Keys.timerTotalDuration)
        UserDefaults.standard.set(currentCycle, forKey: Keys.timerCurrentCycle)
    }

    private func clearPersistence() {
        UserDefaults.standard.removeObject(forKey: Keys.sessionStartDate)
        UserDefaults.standard.removeObject(forKey: Keys.timerEndDate)
        UserDefaults.standard.removeObject(forKey: Keys.timerState)
        UserDefaults.standard.removeObject(forKey: Keys.timerTotalDuration)
        UserDefaults.standard.removeObject(forKey: Keys.timerCurrentCycle)
    }

    private func restoreFromPersistence() {
        guard let stateRaw = UserDefaults.standard.string(forKey: Keys.timerState),
              let savedState = TimerState(rawValue: stateRaw),
              let endTimestamp = UserDefaults.standard.object(forKey: Keys.timerEndDate) as? Double else {
            resetToIdle()
            return
        }

        state = savedState
        totalDuration = UserDefaults.standard.double(forKey: Keys.timerTotalDuration).nonZeroOr(focusDuration)
        currentCycle = UserDefaults.standard.integer(forKey: Keys.timerCurrentCycle)
        endDate = Date(timeIntervalSince1970: endTimestamp)

        if let startTimestamp = UserDefaults.standard.object(forKey: Keys.sessionStartDate) as? Double {
            sessionStartDate = Date(timeIntervalSince1970: startTimestamp)
        }

        recalculateFromDates()

        if timeRemaining <= 0 && savedState != .idle && savedState != .paused {
            completeCurrentPhase()
        } else if savedState != .idle && savedState != .paused {
            startTicking()
        }
    }
}

private extension Double {
    func nonZeroOr(_ fallback: Double) -> Double {
        self > 0 ? self : fallback
    }
}
