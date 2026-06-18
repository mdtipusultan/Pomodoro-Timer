import SwiftUI

struct SettingsView: View {
    @Environment(StoreKitService.self) private var store
    @Environment(SoundService.self) private var soundService
    @Environment(SettingsViewModel.self) private var settings
    @EnvironmentObject private var blockingService: AppBlockingService
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                Section("Timer") {
                    NavigationLink("Timer Settings") {
                        TimerSettingsView()
                    }

                    Picker("Week starts on", selection: Binding(
                        get: { settings.weekStartsOnMonday },
                        set: { settings.weekStartsOnMonday = $0 }
                    )) {
                        Text("Sunday").tag(false)
                        Text("Monday").tag(true)
                    }

                    Picker("Time format", selection: Binding(
                        get: { settings.use24HourTime },
                        set: { settings.use24HourTime = $0 }
                    )) {
                        Text("12-hour").tag(false)
                        Text("24-hour").tag(true)
                    }
                }

                Section("Focus Mode") {
                    Toggle("Strict mode", isOn: $blockingService.strictModeEnabled)

                    NavigationLink("Manage app whitelist") {
                        AppBlockingView()
                    }
                }

                Section("Sound & Haptics") {
                    Toggle("Timer end sound", isOn: Binding(
                        get: { soundService.timerEndSoundEnabled },
                        set: { soundService.timerEndSoundEnabled = $0 }
                    ))
                    Toggle("Break sound", isOn: Binding(
                        get: { soundService.breakSoundEnabled },
                        set: { soundService.breakSoundEnabled = $0 }
                    ))
                    Toggle("Haptic feedback", isOn: Binding(
                        get: { settings.hapticsEnabled },
                        set: { settings.hapticsEnabled = $0 }
                    ))
                }

                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { settings.themeSelection },
                        set: { newValue in
                            if newValue == "dark" && !store.isProUser {
                                showPaywall = true
                            } else {
                                settings.themeSelection = newValue
                            }
                        }
                    )) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }

                    Picker("App Icon", selection: Binding(
                        get: { settings.selectedAppIcon },
                        set: { newValue in
                            if newValue != "default" && !store.isProUser {
                                showPaywall = true
                            } else {
                                settings.selectedAppIcon = newValue
                            }
                        }
                    )) {
                        Text("Default").tag("default")
                        Text("Midnight").tag("midnight")
                        Text("Forest").tag("forest")
                    }
                }

                Section("Pro") {
                    Button("Upgrade to Pro") {
                        showPaywall = true
                    }

                    Button("Restore Purchases") {
                        Task { try? await store.restorePurchases() }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(settings.appVersion)
                            .foregroundStyle(.secondary)
                    }
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(StoreKitService())
        .environment(SoundService())
        .environment(SettingsViewModel())
        .environmentObject(AppBlockingService())
}
