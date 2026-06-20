import Foundation
import SwiftData
import Observation
import SwiftUI

@Observable
@MainActor
final class TimerViewModel {
    let timerService: TimerService
    let soundService: SoundService
    let notificationService: NotificationService
    let liveActivityService: LiveActivityService
    let appState: AppState

    var selectedTag: Tag?
    var showStopConfirmation = false
    var showSuccessAnimation = false
    var showFailedAnimation = false
    var heartsToday: Int = 0

    private var observationTask: Task<Void, Never>?

    init(
        timerService: TimerService,
        soundService: SoundService,
        notificationService: NotificationService,
        liveActivityService: LiveActivityService,
        appState: AppState
    ) {
        self.timerService = timerService
        self.soundService = soundService
        self.notificationService = notificationService
        self.liveActivityService = liveActivityService
        self.appState = appState
        startObserving()
    }

    var timeRemainingText: String {
        timerService.timeRemaining.formattedTimer
    }

    var ringColor: Color {
        timerService.isOnBreak ? .timerBreak : .timerFocus
    }

    func startFocus(modelContext: ModelContext, store: StoreKitService) {
        if store.strictModeCheck() {
            // blocking handled in settings
        }
        timerService.start()
        soundService.playSessionStart()
        notificationService.scheduleSessionEnd(
            in: timerService.timeRemaining,
            isBreak: false
        )
        updateLiveActivity()
        appState.petAnimationState = .focusing
        WatchConnectivityService.shared.sendTimerUpdate(
            state: timerService.state.rawValue,
            timeRemaining: timerService.timeRemaining,
            petType: appState.selectedPetType.rawValue
        )
    }

    func pause() {
        timerService.pause()
        notificationService.cancelPendingNotifications()
        appState.petAnimationState = .idle
    }

    func resume() {
        timerService.start()
        notificationService.scheduleSessionEnd(
            in: timerService.timeRemaining,
            isBreak: timerService.isOnBreak
        )
        appState.petAnimationState = timerService.isOnBreak ? .breakTime : .focusing
    }

    func stop(forced: Bool, modelContext: ModelContext, store: StoreKitService) {
        let wasFocusing = timerService.state == .focusing || timerService.state == .paused
        let shouldPenalize = forced || !timerService.canCancelWithoutPenalty

        if wasFocusing && shouldPenalize {
            saveFailedSession(modelContext: modelContext)
            showFailedAnimation = true
            soundService.playSessionFailed()
            appState.petAnimationState = .failed
        } else {
            timerService.stop(forced: forced)
        }

        notificationService.cancelPendingNotifications()
        liveActivityService.end()
        FloatingTimerManager.shared.hide()
        appState.petAnimationState = .idle
    }

    func confirmStop(modelContext: ModelContext, store: StoreKitService) {
        stop(forced: true, modelContext: modelContext, store: store)
        showStopConfirmation = false
    }

    func handleTimerReachedZero(modelContext: ModelContext, store: StoreKitService) {
        switch timerService.state {
        case .shortBreak, .longBreak:
            saveCompletedSession(modelContext: modelContext, store: store)
            showSuccessAnimation = true
            soundService.playSessionComplete()
            appState.petAnimationState = .success
            heartsToday += 1

            if timerService.isRunning {
                soundService.playBreakStart()
                appState.petAnimationState = .breakTime
                notificationService.scheduleSessionEnd(
                    in: timerService.timeRemaining,
                    isBreak: true
                )
            }
            updateLiveActivity()

        case .idle:
            notificationService.cancelPendingNotifications()
            appState.petAnimationState = .idle
            liveActivityService.end()

        default:
            break
        }
    }
    func skipBreak() {
        timerService.skipBreak()
        appState.petAnimationState = .idle
        notificationService.cancelPendingNotifications()
        liveActivityService.end()
    }

    func refreshHeartsToday(sessions: [FocusSession]) {
        let nightOwl = timerService.nightOwlMode
        let today = Date().startOfDay
        heartsToday = sessions.filter { session in
            session.wasSuccessful &&
            session.startDate.adjustedForNightOwl(nightOwlMode: nightOwl).startOfDay == today
        }.count
    }

    private func saveCompletedSession(modelContext: ModelContext, store: StoreKitService) {
        let startDate = timerService.lastCompletedFocusStartDate ?? timerService.sessionStartDate ?? Date()
        let session = FocusSession(
            startDate: startDate,
            endDate: Date(),
            duration: timerService.focusDuration,
            actualDuration: timerService.focusDuration,
            isCompleted: true,
            isFailed: false,
            tag: selectedTag
        )
        modelContext.insert(session)

        let likabilityBase = Int.random(in: 40...70)
        let likability = store.isProUser ? min(100, likabilityBase * 2) : likabilityBase
        let pet = Pet(
            type: appState.selectedPetType,
            raisedDate: Date(),
            sessionId: session.id,
            likability: likability
        )
        modelContext.insert(pet)
        appState.incrementUnviewedPets()
        try? modelContext.save()
        timerService.clearLastCompletedFocusStartDate()
    }

    private func saveFailedSession(modelContext: ModelContext) {
        let elapsed = timerService.sessionStartDate.map { Date().timeIntervalSince($0) } ?? 0
        let session = FocusSession(
            startDate: timerService.sessionStartDate ?? Date(),
            endDate: Date(),
            duration: timerService.focusDuration,
            actualDuration: elapsed,
            isCompleted: false,
            isFailed: true,
            tag: selectedTag
        )
        modelContext.insert(session)
        try? modelContext.save()
        timerService.stop(forced: true)
    }

    private func updateLiveActivity() {
        liveActivityService.update(
            timeRemaining: timerService.timeRemaining,
            totalDuration: timerService.totalDuration,
            sessionType: timerService.stateLabel,
            tagName: selectedTag?.name
        )
    }

    private func startObserving() {
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { break }
                if self.timerService.isRunning {
                    self.updateLiveActivity()
                    WatchConnectivityService.shared.sendTimerUpdate(
                        state: self.timerService.state.rawValue,
                        timeRemaining: self.timerService.timeRemaining,
                        petType: self.appState.selectedPetType.rawValue
                    )
                }
            }
        }
    }
}

private extension StoreKitService {
    func strictModeCheck() -> Bool {
        false
    }
}
