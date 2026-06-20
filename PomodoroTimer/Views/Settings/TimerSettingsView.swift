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
                    Text("Focus: \(Int(timer.focusDuration / 60)) min")
                }

                Stepper(value: shortBreakMinutesBinding, in: 1...30, step: 1) {
                    Text("Short Break: \(Int(timer.shortBreakDuration / 60)) min")
                }

                if store.isProUser {
                    Stepper(value: longBreakMinutesBinding, in: 5...60, step: 5) {
                        Text("Long Break: \(Int(timer.longBreakDuration / 60)) min")
                    }
                } else {
                    HStack {
                        Text("Long Break")
                        Spacer()
                        Text("\(Int(timer.longBreakDuration / 60)) min")
                            .foregroundStyle(.secondary)
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture { showPaywall = true }
                }

                Stepper(value: $timer.cyclesBeforeLongBreak, in: 1...8) {
                    Text("Cycles before long break: \(timer.cyclesBeforeLongBreak)")
                }
            }

            Section {
                Toggle("Auto-start breaks", isOn: $timer.autoStartBreaks)

                Toggle("Night Owl mode", isOn: Binding(
                    get: { settings.nightOwlMode },
                    set: { newValue in
                        if store.isProUser || !newValue {
                            settings.nightOwlMode = newValue
                            timer.nightOwlMode = newValue
                        } else {
                            showPaywall = true
                        }
                    }
                ))
            }
        }
        .navigationTitle("Timer Settings")
        .sheet(isPresented: $showPaywall) {
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
