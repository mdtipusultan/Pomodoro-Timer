import SwiftUI

struct TimerSettingsView: View {
    @Environment(TimerService.self) private var timerService
    @Environment(SettingsViewModel.self) private var settings
    @Environment(StoreKitService.self) private var store
    @State private var showPaywall = false

    var body: some View {
        @Bindable var timer = timerService

        List {
            Section("Durations") {
                Stepper(value: focusMinutesBinding, in: 5...120, step: 5) {
                    Label("Focus: \(Int(timer.focusDuration / 60)) min", systemImage: "target")
                }

                Stepper(value: shortBreakMinutesBinding, in: 1...30, step: 1) {
                    Label("Short Break: \(Int(timer.shortBreakDuration / 60)) min", systemImage: "cup.and.saucer")
                }

                if store.isProUser {
                    Stepper(value: longBreakMinutesBinding, in: 5...60, step: 5) {
                        Label("Long Break: \(Int(timer.longBreakDuration / 60)) min", systemImage: "leaf")
                    }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Label("Long Break", systemImage: "leaf")
                            Spacer()
                            Text("\(Int(timer.longBreakDuration / 60)) min")
                                .foregroundStyle(.secondary)
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Stepper(value: $timer.cyclesBeforeLongBreak, in: 1...8) {
                    Label("Cycles before long break: \(timer.cyclesBeforeLongBreak)", systemImage: "repeat")
                }
            }

            Section {
                Toggle(isOn: $timer.autoStartBreaks) {
                    Label("Auto-start breaks", systemImage: "play.circle")
                }

                Toggle(isOn: Binding(
                    get: { settings.nightOwlMode },
                    set: { newValue in
                        if store.isProUser || !newValue {
                            settings.nightOwlMode = newValue
                            timer.nightOwlMode = newValue
                        } else {
                            showPaywall = true
                        }
                    }
                )) {
                    Label("Night Owl mode", systemImage: "moon.stars")
                }
            }
        }
        .appThemedList()
        .tint(.appOrange)
        .navigationTitle("Timer Settings")
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var focusMinutesBinding: Binding<Int> {
        Binding(
            get: { Int(timerService.focusDuration / 60) },
            set: { timerService.focusDuration = TimeInterval($0 * 60) }
        )
    }

    private var shortBreakMinutesBinding: Binding<Int> {
        Binding(
            get: { Int(timerService.shortBreakDuration / 60) },
            set: { timerService.shortBreakDuration = TimeInterval($0 * 60) }
        )
    }

    private var longBreakMinutesBinding: Binding<Int> {
        Binding(
            get: { Int(timerService.longBreakDuration / 60) },
            set: { timerService.longBreakDuration = TimeInterval($0 * 60) }
        )
    }
}

#Preview {
    NavigationStack {
        TimerSettingsView()
            .environment(TimerService())
            .environment(SettingsViewModel())
            .environment(StoreKitService())
    }
}
