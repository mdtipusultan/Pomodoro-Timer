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
    // FAMILY_CONTROLS_DISABLED
    // var blockingService: AppBlockingService?

    var selectedTag: Tag?
    var showStopConfirmation = false
    var showSuccessAnimation = false
    var showFailedAnimation = false
    var heartsToday = 0

    private var observationTask: Task<Void, Never>?
    private var lastHandledPhaseCompletionCount = 0

    init(
        timerService: TimerService,
        soundService: SoundService,
        notificationService: NotificationService,
        liveActivityService: LiveActivityService,
        appState: AppState
        // FAMILY_CONTROLS_DISABLED
        // blockingService: AppBlockingService? = nil
    ) {
        self.timerService = timerService
        self.soundService = soundService
        self.notificationService = notificationService
        self.liveActivityService = liveActivityService
        self.appState = appState
        // FAMILY_CONTROLS_DISABLED
        // self.blockingService = blockingService
        startObserving()
    }

    var timeRemainingText: String {
        timerService.timeRemaining.formattedTimer
    }

    var ringColor: Color {
        timerService.isOnBreak ? .timerBreak : .timerFocus
    }

    func startFocus(modelContext: ModelContext, store: StoreKitService) {
        // FAMILY_CONTROLS_DISABLED
        // if blockingService?.strictModeEnabled == true {
        //     blockingService?.startBlocking()
        // }
        timerService.start()
        soundService.playSessionStart()
        HapticManager.shared.timerStart()
        notificationService.scheduleSessionEnd(
            in: timerService.timeRemaining,
            isBreak: false
        )
        liveActivityService.start(
            petType: appState.selectedPetType,
            tagName: selectedTag?.name,
            timeRemaining: timerService.timeRemaining,
            totalDuration: timerService.totalDuration,
            sessionType: timerService.stateLabel
        )
        appState.petAnimationState = .focusing
        WatchConnectivityService.shared.sendTimerUpdate(
            state: timerService.state.rawValue,
            timeRemaining: timerService.timeRemaining,
            petType: appState.selectedPetType.rawValue
        )
    }

    func startBreak() {
        // FAMILY_CONTROLS_DISABLED
        // blockingService?.stopBlocking()
        timerService.startBreak()
        soundService.playBreakStart()
        HapticManager.shared.timerStart()
        notificationService.scheduleSessionEnd(
            in: timerService.timeRemaining,
            isBreak: true
        )
        liveActivityService.start(
            petType: appState.selectedPetType,
            tagName: selectedTag?.name,
            timeRemaining: timerService.timeRemaining,
            totalDuration: timerService.totalDuration,
            sessionType: timerService.stateLabel
        )
        appState.petAnimationState = .breakTime
    }

    func pause() {
        timerService.pause()
        HapticManager.shared.timerPause()
        notificationService.cancelPendingNotifications()
        appState.petAnimationState = .idle
    }

    func resume() {
        // FAMILY_CONTROLS_DISABLED
        // if blockingService?.strictModeEnabled == true, timerService.stateBeforePauseIsFocus {
        //     blockingService?.startBlocking()
        // }
        timerService.start()
        HapticManager.shared.timerStart()
        notificationService.scheduleSessionEnd(
            in: timerService.timeRemaining,
            isBreak: timerService.isOnBreak
        )
        appState.petAnimationState = timerService.isOnBreak ? .breakTime : .focusing
        liveActivityService.start(
            petType: appState.selectedPetType,
            tagName: selectedTag?.name,
            timeRemaining: timerService.timeRemaining,
            totalDuration: timerService.totalDuration,
            sessionType: timerService.stateLabel
        )
    }

    func stop(forced: Bool, modelContext: ModelContext, store: StoreKitService) {
        let wasFocusing = timerService.state == .focusing || timerService.state == .paused
        let shouldPenalize = forced || !timerService.canCancelWithoutPenalty

        // FAMILY_CONTROLS_DISABLED
        // blockingService?.stopBlocking()
        notificationService.cancelPendingNotifications()
        liveActivityService.end()
        FloatingTimerManager.shared.hide()

        if wasFocusing && shouldPenalize {
            saveFailedSession(modelContext: modelContext)
            showFailedAnimation = true
            soundService.playSessionFailed()
            HapticManager.shared.sessionFailed()
            appState.petAnimationState = .failed
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                appState.petAnimationState = .idle
            }
        } else {
            timerService.stop(forced: forced)
            HapticManager.shared.timerStop()
            appState.petAnimationState = .idle
        }
    }

    func confirmStop(modelContext: ModelContext, store: StoreKitService) {
        stop(forced: true, modelContext: modelContext, store: store)
        showStopConfirmation = false
    }

    func processPendingPhaseCompletion(modelContext: ModelContext, store: StoreKitService) {
        guard timerService.phaseCompletionCount > lastHandledPhaseCompletionCount,
              let phase = timerService.lastCompletedPhase else { return }
        lastHandledPhaseCompletionCount = timerService.phaseCompletionCount
        handlePhaseCompleted(phase, modelContext: modelContext, store: store)
    }

    func handlePhaseCompleted(
        _ completedPhase: TimerService.TimerState,
        modelContext: ModelContext,
        store: StoreKitService
    ) {
        switch completedPhase {
        case .focusing:
            saveCompletedSession(modelContext: modelContext, store: store)
            showSuccessAnimation = true
            soundService.playSessionComplete()
            HapticManager.shared.sessionComplete()
            appState.petAnimationState = .success
            heartsToday += 1
            // FAMILY_CONTROLS_DISABLED
            // blockingService?.stopBlocking()

            if timerService.isOnBreak {
                soundService.playBreakStart()
                appState.petAnimationState = .breakTime
                if timerService.isRunning {
                    notificationService.scheduleSessionEnd(
                        in: timerService.timeRemaining,
                        isBreak: true
                    )
                    liveActivityService.start(
                        petType: appState.selectedPetType,
                        tagName: selectedTag?.name,
                        timeRemaining: timerService.timeRemaining,
                        totalDuration: timerService.totalDuration,
                        sessionType: timerService.stateLabel
                    )
                } else {
                    liveActivityService.end()
                }
            } else {
                liveActivityService.end()
            }

        case .shortBreak, .longBreak:
            notificationService.cancelPendingNotifications()
            appState.petAnimationState = .idle
            liveActivityService.end()
            // FAMILY_CONTROLS_DISABLED
            // blockingService?.stopBlocking()

        default:
            break
        }
    }

    func skipBreak() {
        timerService.skipBreak()
        appState.petAnimationState = .idle
        notificationService.cancelPendingNotifications()
        liveActivityService.end()
        // FAMILY_CONTROLS_DISABLED
        // blockingService?.stopBlocking()
    }

    func refreshHeartsToday(sessions: [FocusSession]) {
        let nightOwl = timerService.nightOwlMode
        let today = Date().startOfDay
        heartsToday = sessions.filter { session in
            session.wasSuccessful &&
            session.startDate.adjustedForNightOwl(nightOwlMode: nightOwl).startOfDay == today
        }.count
        WidgetDataStore.refresh(
            sessions: sessions,
            nightOwlMode: nightOwl,
            weekStartsOnMonday: UserDefaults.standard.bool(forKey: "weekStartsOnMonday")
        )
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

    private func startObserving() {
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { break }
                if self.timerService.isRunning {
                    self.liveActivityService.update(
                        timeRemaining: self.timerService.timeRemaining,
                        totalDuration: self.timerService.totalDuration,
                        sessionType: self.timerService.stateLabel,
                        tagName: self.selectedTag?.name
                    )
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
