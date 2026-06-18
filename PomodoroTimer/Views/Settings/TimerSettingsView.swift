import SwiftUI

struct TimerSettingsView: View {
    @Environment(TimerService.self) private var timerService
    @Environment(SettingsViewModel.self) private var settings
    @Environment(StoreKitService.self) private var store
    @State private var showPaywall = false

    var body: some View {
        List {
            Section("Durations") {
                Stepper("Focus: \(Int(timerService.focusDuration / 60)) min") {
                    let current = Int(timerService.focusDuration / 60)
                    if current < 120 { timerService.focusDuration = TimeInterval((current + 5) * 60) }
                } onDecrement: {
                    let current = Int(timerService.focusDuration / 60)
                    if current > 5 { timerService.focusDuration = TimeInterval((current - 5) * 60) }
                }

                Stepper("Short Break: \(Int(timerService.shortBreakDuration / 60)) min") {
                    let current = Int(timerService.shortBreakDuration / 60)
                    if current < 30 { timerService.shortBreakDuration = TimeInterval((current + 1) * 60) }
                } onDecrement: {
                    let current = Int(timerService.shortBreakDuration / 60)
                    if current > 1 { timerService.shortBreakDuration = TimeInterval((current - 1) * 60) }
                }

                if store.isProUser {
                    Stepper("Long Break: \(Int(timerService.longBreakDuration / 60)) min") {
                        let current = Int(timerService.longBreakDuration / 60)
                        if current < 60 { timerService.longBreakDuration = TimeInterval((current + 5) * 60) }
                    } onDecrement: {
                        let current = Int(timerService.longBreakDuration / 60)
                        if current > 5 { timerService.longBreakDuration = TimeInterval((current - 5) * 60) }
                    }
                } else {
                    HStack {
                        Text("Long Break")
                        Spacer()
                        Text("\(Int(timerService.longBreakDuration / 60)) min")
                            .foregroundStyle(.secondary)
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture { showPaywall = true }
                }

                Stepper("Cycles before long break: \(timerService.cyclesBeforeLongBreak)", value: Binding(
                    get: { timerService.cyclesBeforeLongBreak },
                    set: { timerService.cyclesBeforeLongBreak = $0 }
                ), in: 1...8)
            }

            Section {
                Toggle("Auto-start breaks", isOn: Binding(
                    get: { timerService.autoStartBreaks },
                    set: { timerService.autoStartBreaks = $0 }
                ))

                Toggle("Night Owl mode", isOn: Binding(
                    get: { settings.nightOwlMode },
                    set: { newValue in
                        if store.isProUser || !newValue {
                            settings.nightOwlMode = newValue
                            timerService.nightOwlMode = newValue
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
}

#Preview {
    NavigationStack {
        TimerSettingsView()
            .environment(TimerService())
            .environment(SettingsViewModel())
            .environment(StoreKitService())
    }
}
