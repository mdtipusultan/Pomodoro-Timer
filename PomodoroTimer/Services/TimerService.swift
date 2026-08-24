import Foundation
import Observation

@Observable
@MainActor
final class TimerService {
    enum TimerState: String {
        case idle, focusing, shortBreak, longBreak, paused
    }

    enum TimerMode: String {
        case pomodoro, countdown
    }

    var state: TimerState = .idle
    var mode: TimerMode = .pomodoro {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: AppGroup.Keys.timerMode) }
    }
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
    private var stateBeforePause: TimerState = .focusing

    var canCancelWithoutPenalty: Bool {
        guard let start = sessionStartDate else { return true }
        return Date().timeIntervalSince(start) < 10
    }

    var isRunning: Bool {
        (state == .focusing || state == .shortBreak || state == .longBreak) && endDate != nil
    }

    var isOnBreak: Bool {
        state == .shortBreak || state == .longBreak
    }

    var isAwaitingBreakStart: Bool {
        isOnBreak && endDate == nil
    }

    var stateBeforePauseIsFocus: Bool {
        stateBeforePause == .focusing
    }

    var stateLabel: String {
        switch state {
        case .idle: return "Ready"
        case .focusing: return "Focusing"
        case .shortBreak: return isAwaitingBreakStart ? "Break Ready" : "Short Break"
        case .longBreak: return isAwaitingBreakStart ? "Long Break Ready" : "Long Break"
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
        static let pausedRemaining = "timerPausedRemaining"
        static let stateBeforePause = "timerStateBeforePause"
    }

    init() {
        focusDuration = UserDefaults.standard.double(forKey: Keys.focusDuration).nonZeroOr(25 * 60)
        shortBreakDuration = UserDefaults.standard.double(forKey: Keys.shortBreakDuration).nonZeroOr(5 * 60)
        longBreakDuration = UserDefaults.standard.double(forKey: Keys.longBreakDuration).nonZeroOr(15 * 60)
        let savedCycles = UserDefaults.standard.integer(forKey: Keys.cyclesBeforeLongBreak)
        cyclesBeforeLongBreak = savedCycles > 0 ? savedCycles : 4
        autoStartBreaks = UserDefaults.standard.bool(forKey: Keys.autoStartBreaks)
        nightOwlMode = UserDefaults.standard.bool(forKey: Keys.nightOwlMode)
        if let raw = UserDefaults.standard.string(forKey: AppGroup.Keys.timerMode),
           let savedMode = TimerMode(rawValue: raw) {
            mode = savedMode
        }
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

        state = .focusing
        totalDuration = focusDuration
        timeRemaining = focusDuration
        sessionStartDate = Date()
        endDate = Date().addingTimeInterval(timeRemaining)
        persistState()
        startTicking()
    }

    func startBreak(isLong: Bool? = nil) {
        if isAwaitingBreakStart {
            sessionStartDate = Date()
            endDate = Date().addingTimeInterval(timeRemaining)
            persistState()
            startTicking()
            return
        }

        let useLong = isLong ?? (currentCycle > 0 && currentCycle % cyclesBeforeLongBreak == 0)
        state = useLong ? .longBreak : .shortBreak
        totalDuration = useLong ? longBreakDuration : shortBreakDuration
        timeRemaining = totalDuration
        sessionStartDate = Date()
        endDate = Date().addingTimeInterval(timeRemaining)
        persistState()
        startTicking()
    }

    func pause() {
        guard isRunning else { return }
        recalculateFromDates()
        stateBeforePause = state
        pausedAtDate = Date()
        state = .paused
        endDate = nil
        tickTask?.cancel()
        tickTask = nil
        persistState()
    }

    func stop(forced: Bool = false) {
        tickTask?.cancel()
        tickTask = nil
        clearPersistence()
        resetToIdle()
    }

    func skipBreak() {
        let wasLong = state == .longBreak || (state == .paused && stateBeforePause == .longBreak)
        guard isOnBreak || (state == .paused && (stateBeforePause == .shortBreak || stateBeforePause == .longBreak)) else { return }
        tickTask?.cancel()
        tickTask = nil
        if wasLong {
            currentCycle = 0
        }
        resetToIdle()
        clearPersistence()
    }

    func completeCurrentPhase() {
        tickTask?.cancel()
        tickTask = nil

        let completedPhase = state

        if mode == .countdown && state == .focusing {
            lastCompletedFocusStartDate = sessionStartDate
            lastCompletedPhase = .focusing
            phaseCompletionCount += 1
            resetToIdle()
            clearPersistence()
            return
        }

        switch state {
        case .focusing:
            lastCompletedFocusStartDate = sessionStartDate
            currentCycle += 1
            let isLongBreak = currentCycle > 0 && currentCycle % cyclesBeforeLongBreak == 0
            if autoStartBreaks {
                startBreak(isLong: isLongBreak)
            } else {
                state = isLongBreak ? .longBreak : .shortBreak
                totalDuration = isLongBreak ? longBreakDuration : shortBreakDuration
                timeRemaining = totalDuration
                sessionStartDate = nil
                endDate = nil
                persistAwaitingBreak()
            }
        case .shortBreak, .longBreak:
            if state == .longBreak {
                currentCycle = 0
            }
            resetToIdle()
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
        if state == .paused { return }
        guard endDate != nil else { return }
        recalculateFromDates()
        if timeRemaining <= 0 && (state == .focusing || isOnBreak) {
            completeCurrentPhase()
        } else if isRunning {
            startTicking()
        }
    }

    func handleBackground() {
        persistState()
    }

    private func resumeFromPause() {
        if let pausedAt = pausedAtDate {
            accumulatedPausedTime += Date().timeIntervalSince(pausedAt)
        }
        pausedAtDate = nil
        state = stateBeforePause
        endDate = Date().addingTimeInterval(timeRemaining)
        persistState()
        startTicking()
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
    }

    private func persistAwaitingBreak() {
        UserDefaults.standard.set(state.rawValue, forKey: Keys.timerState)
        UserDefaults.standard.set(totalDuration, forKey: Keys.timerTotalDuration)
        UserDefaults.standard.set(currentCycle, forKey: Keys.timerCurrentCycle)
        UserDefaults.standard.set(timeRemaining, forKey: Keys.pausedRemaining)
        UserDefaults.standard.removeObject(forKey: Keys.timerEndDate)
        UserDefaults.standard.removeObject(forKey: Keys.sessionStartDate)
    }

    private func persistState() {
        UserDefaults.standard.set(sessionStartDate?.timeIntervalSince1970, forKey: Keys.sessionStartDate)
        UserDefaults.standard.set(endDate?.timeIntervalSince1970, forKey: Keys.timerEndDate)
        UserDefaults.standard.set(state.rawValue, forKey: Keys.timerState)
        UserDefaults.standard.set(totalDuration, forKey: Keys.timerTotalDuration)
        UserDefaults.standard.set(currentCycle, forKey: Keys.timerCurrentCycle)
        UserDefaults.standard.set(timeRemaining, forKey: Keys.pausedRemaining)
        UserDefaults.standard.set(stateBeforePause.rawValue, forKey: Keys.stateBeforePause)
    }

    private func clearPersistence() {
        UserDefaults.standard.removeObject(forKey: Keys.sessionStartDate)
        UserDefaults.standard.removeObject(forKey: Keys.timerEndDate)
        UserDefaults.standard.removeObject(forKey: Keys.timerState)
        UserDefaults.standard.removeObject(forKey: Keys.timerTotalDuration)
        UserDefaults.standard.removeObject(forKey: Keys.pausedRemaining)
        UserDefaults.standard.removeObject(forKey: Keys.stateBeforePause)
    }

    private func restoreFromPersistence() {
        currentCycle = UserDefaults.standard.integer(forKey: Keys.timerCurrentCycle)

        if let raw = UserDefaults.standard.string(forKey: Keys.stateBeforePause),
           let previous = TimerState(rawValue: raw) {
            stateBeforePause = previous
        }

        guard let stateRaw = UserDefaults.standard.string(forKey: Keys.timerState),
              let savedState = TimerState(rawValue: stateRaw) else {
            resetToIdle()
            return
        }

        totalDuration = UserDefaults.standard.double(forKey: Keys.timerTotalDuration).nonZeroOr(focusDuration)

        if let startTimestamp = UserDefaults.standard.object(forKey: Keys.sessionStartDate) as? Double {
            sessionStartDate = Date(timeIntervalSince1970: startTimestamp)
        }

        if savedState == .paused {
            state = .paused
            timeRemaining = UserDefaults.standard.double(forKey: Keys.pausedRemaining).nonZeroOr(focusDuration)
            endDate = nil
            return
        }

        if (savedState == .shortBreak || savedState == .longBreak),
           UserDefaults.standard.object(forKey: Keys.timerEndDate) == nil {
            state = savedState
            let fallback = savedState == .longBreak ? longBreakDuration : shortBreakDuration
            timeRemaining = UserDefaults.standard.double(forKey: Keys.pausedRemaining).nonZeroOr(fallback)
            endDate = nil
            return
        }

        guard let endTimestamp = UserDefaults.standard.object(forKey: Keys.timerEndDate) as? Double else {
            state = savedState
            if savedState == .idle {
                timeRemaining = focusDuration
            }
            return
        }

        state = savedState
        endDate = Date(timeIntervalSince1970: endTimestamp)
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
