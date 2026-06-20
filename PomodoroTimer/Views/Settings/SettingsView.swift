import SwiftUI

struct SettingsView: View {
    @Environment(StoreKitService.self) private var store
    @Environment(SoundService.self) private var soundService
    @Environment(SettingsViewModel.self) private var settings
    @EnvironmentObject private var blockingService: AppBlockingService
    @State private var showPaywall = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            List {
                Section("Timer") {
                    NavigationLink("Timer Settings") {
                        TimerSettingsView()
                    }

                    Picker("Week starts on", selection: $settings.weekStartsOnMonday) {
                        Text("Sunday").tag(false)
                        Text("Monday").tag(true)
                    }

                    Picker("Time format", selection: $settings.use24HourTime) {
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
                    Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                }

                Section("Appearance") {
                    Picker("Theme", selection: themeBinding) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }

                    Picker("App Icon", selection: appIconBinding) {
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

    private var themeBinding: Binding<String> {
        Binding(
            get: { settings.themeSelection },
            set: { newValue in
                if newValue == "dark" && !store.isProUser {
                    showPaywall = true
                } else {
                    settings.themeSelection = newValue
                }
            }
        )
    }

    private var appIconBinding: Binding<String> {
        Binding(
            get: { settings.selectedAppIcon },
            set: { newValue in
                if newValue != "default" && !store.isProUser {
                    showPaywall = true
                } else {
                    settings.selectedAppIcon = newValue
                }
            }
        )
    }
}

#Preview {
    SettingsView()
        .environment(StoreKitService())
        .environment(SoundService())
        .environment(SettingsViewModel())
        .environmentObject(AppBlockingService())
}
