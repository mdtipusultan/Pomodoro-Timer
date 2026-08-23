import SwiftData
import SwiftUI

struct TimerView: View {
    @Environment(TimerService.self) private var timerService
    @Environment(SoundService.self) private var soundService
    @Environment(AppState.self) private var appState
    @Environment(StoreKitService.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]
    @Query(sort: \FocusSession.startDate, order: .reverse) private var sessions: [FocusSession]

    @State private var viewModel: TimerViewModel?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TagSelectorView(
                    selectedTag: Binding(
                        get: { viewModel?.selectedTag },
                        set: { viewModel?.selectedTag = $0 }
                    ),
                    tags: tags
                )
                .padding(.top, 4)

                ZStack {
                    Circle()
                        .fill((viewModel?.ringColor ?? .timerFocus).opacity(0.12))
                        .frame(width: 310, height: 310)
                        .blur(radius: 40)

                    TimerRingView(
                        progress: timerService.progress,
                        color: viewModel?.ringColor ?? .timerFocus,
                        lineWidth: 13
                    )
                    .frame(width: 290, height: 290)

                    VStack(spacing: 10) {
                        PetAnimationView(
                            petType: appState.selectedPetType,
                            animationState: appState.petAnimationState
                        )
                        .onTapGesture {
                            if timerService.isOnBreak {
                                soundService.playPurr()
                                HapticManager.shared.petInteraction()
                            }
                        }
                        .accessibilityLabel("Pet companion")
                        .accessibilityHint(timerService.isOnBreak ? "Tap to interact" : "")
                        .accessibilityAddTraits(.isButton)

                        Text(viewModel?.timeRemainingText ?? timerService.timeRemaining.formattedTimer)
                            .font(.system(size: 52, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .accessibilityLabel("Time remaining: \(viewModel?.timeRemainingText ?? timerService.timeRemaining.formattedTimer)")

                        Text(timerService.stateLabel)
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .foregroundStyle(viewModel?.ringColor ?? .timerFocus)
                            .background(
                                (viewModel?.ringColor ?? .timerFocus).opacity(0.14),
                                in: Capsule()
                            )
                            .accessibilityLabel("Timer state: \(timerService.stateLabel)")
                    }
                }
                .padding(.vertical, 8)

                controlButtons

                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.subheadline)
                        .foregroundStyle(.pink)
                    Text("\(viewModel?.heartsToday ?? 0) hearts today")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .appCardStyle(radius: 20)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(viewModel?.heartsToday ?? 0) completed sessions today")

                Spacer()
            }
            .padding(.top, 4)
            .appScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Focus")
                        .font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(PetType.allCases, id: \.self) { pet in
                            Button {
                                if store.hasPurchased(petType: pet) {
                                    appState.selectedPetType = pet
                                } else {
                                    showPaywall = true
                                }
                            } label: {
                                Label(pet.displayName, systemImage: pet.systemImage)
                            }
                        }
                    } label: {
                        Image(systemName: appState.selectedPetType.systemImage)
                            .font(.title3)
                            .foregroundStyle(appState.selectedPetType.color)
                    }
                }
            }
            .alert("Stop Session?", isPresented: Binding(
                get: { viewModel?.showStopConfirmation ?? false },
                set: { viewModel?.showStopConfirmation = $0 }
            )) {
                Button("Keep Going", role: .cancel) {}
                Button("Stop", role: .destructive) {
                    viewModel?.confirmStop(modelContext: modelContext, store: store)
                }
            } message: {
                Text("Your companion won't grow if you stop now.")
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = TimerViewModel(
                        timerService: timerService,
                        soundService: soundService,
                        notificationService: .shared,
                        liveActivityService: LiveActivityService(),
                        appState: appState
                    )
                }
                viewModel?.refreshHeartsToday(sessions: sessions)
                viewModel?.processPendingPhaseCompletion(modelContext: modelContext, store: store)
                if viewModel?.selectedTag == nil {
                    viewModel?.selectedTag = tags.first
                }
            }
            .onChange(of: sessions.count) { _, _ in
                viewModel?.refreshHeartsToday(sessions: sessions)
            }
            .onChange(of: timerService.phaseCompletionCount) { _, _ in
                viewModel?.processPendingPhaseCompletion(modelContext: modelContext, store: store)
            }
            .onChange(of: timerService.timeRemaining) { _, new in
                if new <= 10 && new > 0 && timerService.isRunning {
                    soundService.playTick()
                }
            }
        }
    }

    @ViewBuilder
    private var controlButtons: some View {
        VStack(spacing: 12) {
            if timerService.state == .idle {
                Button {
                    viewModel?.startFocus(modelContext: modelContext, store: store)
                } label: {
                    Label("Start Focus", systemImage: "play.fill")
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .accessibilityLabel("Start focus session")
                .accessibilityHint("Begins a \(Int(timerService.focusDuration / 60)) minute focus session")
            } else if timerService.isOnBreak && timerService.state != .paused {
                Button {
                    viewModel?.skipBreak()
                } label: {
                    Label("Skip Break", systemImage: "forward.fill")
                }
                .buttonStyle(AppPrimaryButtonStyle(color: .breakGreen))
                .accessibilityLabel("Skip break")
                .accessibilityHint("Skip the break and return to focus mode")
            } else if timerService.state == .paused {
                HStack(spacing: 12) {
                    Button {
                        if timerService.canCancelWithoutPenalty {
                            viewModel?.stop(forced: false, modelContext: modelContext, store: store)
                        } else {
                            viewModel?.showStopConfirmation = true
                        }
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(AppSecondaryButtonStyle(tint: .dangerRed, fill: Color.dangerRed.opacity(0.14)))

                    Button {
                        viewModel?.resume()
                    } label: {
                        Label("Resume", systemImage: "play.fill")
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                }
            } else if timerService.isRunning {
                HStack(spacing: 12) {
                    Button {
                        if timerService.canCancelWithoutPenalty {
                            viewModel?.stop(forced: false, modelContext: modelContext, store: store)
                        } else {
                            viewModel?.showStopConfirmation = true
                        }
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(AppSecondaryButtonStyle(tint: .dangerRed, fill: Color.dangerRed.opacity(0.14)))

                    Button {
                        timerService.pause()
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    TimerView()
        .environment(TimerService())
        .environment(SoundService())
        .environment(AppState())
        .environment(StoreKitService())
}
