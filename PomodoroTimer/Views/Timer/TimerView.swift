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
    @State private var showMenu = false
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

                ZStack {
                    TimerRingView(
                        progress: timerService.progress,
                        color: viewModel?.ringColor ?? .timerFocus,
                        lineWidth: 14
                    )
                    .frame(width: 280, height: 280)

                    VStack(spacing: 12) {
                        PetAnimationView(
                            petType: appState.selectedPetType,
                            animationState: appState.petAnimationState
                        )
                        .onTapGesture {
                            if timerService.isOnBreak {
                                soundService.playPurr()
                            }
                        }

                        Text(viewModel?.timeRemainingText ?? timerService.timeRemaining.formattedTimer)
                            .font(.system(size: 48, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        Text(timerService.stateLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)

                controlButtons

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                    Text("\(viewModel?.heartsToday ?? 0) hearts today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.top)
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.primary)
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
            .sheet(isPresented: $showPaywall) {
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
                if viewModel?.selectedTag == nil {
                    viewModel?.selectedTag = tags.first
                }
            }
            .onChange(of: sessions.count) { _, _ in
                viewModel?.refreshHeartsToday(sessions: sessions)
            }
            .onChange(of: timerService.timeRemaining) { old, new in
                if old > 0 && new <= 0 {
                    viewModel?.handleSessionComplete(modelContext: modelContext, store: store)
                }
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
                    Text("Start Focus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appOrange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            } else if timerService.state == .paused {
                HStack(spacing: 16) {
                    Button {
                        if timerService.canCancelWithoutPenalty {
                            viewModel?.stop(forced: false, modelContext: modelContext, store: store)
                        } else {
                            viewModel?.showStopConfirmation = true
                        }
                    } label: {
                        Text("Stop")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dangerRed.opacity(0.15))
                            .foregroundStyle(Color.dangerRed)
                            .clipShape(Capsule())
                    }

                    Button {
                        viewModel?.resume()
                    } label: {
                        Text("Resume")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appOrange)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            } else if timerService.isRunning {
                HStack(spacing: 16) {
                    Button {
                        if timerService.canCancelWithoutPenalty {
                            viewModel?.stop(forced: false, modelContext: modelContext, store: store)
                        } else {
                            viewModel?.showStopConfirmation = true
                        }
                    } label: {
                        Text("Stop")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dangerRed.opacity(0.15))
                            .foregroundStyle(Color.dangerRed)
                            .clipShape(Capsule())
                    }

                    Button {
                        timerService.pause()
                    } label: {
                        Text("Pause")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appSecondary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(Capsule())
                    }
                }
            } else if timerService.isOnBreak {
                Button {
                    viewModel?.skipBreak()
                } label: {
                    Text("Skip Break")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.breakGreen)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
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
