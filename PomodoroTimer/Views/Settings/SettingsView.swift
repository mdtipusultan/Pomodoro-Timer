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
                if !store.isProUser {
                    Section {
                        Button {
                            HapticManager.shared.buttonTap()
                            showPaywall = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.20))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "sparkles")
                                        .font(.title3)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("ChickFocus Pro")
                                        .font(.headline)
                                    Text("Unlock history, companions, and more")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.88))
                                }
                                Spacer()
                                Text("Upgrade")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(.white.opacity(0.24), in: Capsule())
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.appOrangeGradient)
                    }
                }

                Section("Timer") {
                    NavigationLink {
                        TimerSettingsView()
                    } label: {
                        Label("Timer Settings", systemImage: "timer")
                    }

                    Picker(selection: $settings.weekStartsOnMonday) {
                        Text("Sunday").tag(false)
                        Text("Monday").tag(true)
                    } label: {
                        Label("Week starts on", systemImage: "calendar")
                    }

                    Picker(selection: $settings.use24HourTime) {
                        Text("12-hour").tag(false)
                        Text("24-hour").tag(true)
                    } label: {
                        Label("Time format", systemImage: "clock")
                    }
                }

                Section("Focus Mode") {
                    Toggle(isOn: $blockingService.strictModeEnabled) {
                        Label("Strict mode", systemImage: "lock.shield")
                    }

                    NavigationLink {
                        AppBlockingView()
                    } label: {
                        Label("Manage app whitelist", systemImage: "apps.iphone")
                    }
                }

                Section("Sound & Haptics") {
                    Toggle(isOn: Binding(
                        get: { soundService.timerEndSoundEnabled },
                        set: { soundService.timerEndSoundEnabled = $0 }
                    )) {
                        Label("Timer end sound", systemImage: "bell")
                    }
                    Toggle(isOn: Binding(
                        get: { soundService.breakSoundEnabled },
                        set: { soundService.breakSoundEnabled = $0 }
                    )) {
                        Label("Break sound", systemImage: "leaf")
                    }
                    Toggle(isOn: $settings.hapticsEnabled) {
                        Label("Haptic feedback", systemImage: "hand.tap")
                    }
                }

                Section("Appearance") {
                    Picker(selection: themeBinding) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    } label: {
                        Label("Theme", systemImage: "circle.lefthalf.filled")
                    }

                    Picker(selection: appIconBinding) {
                        Text("Default").tag("default")
                        Text("Midnight").tag("midnight")
                        Text("Forest").tag("forest")
                    } label: {
                        Label("App Icon", systemImage: "app.gift")
                    }
                }

                Section("Pro") {
                    if store.isProUser {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.appOrange)
                            Text("You're a Pro member")
                            Spacer()
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(Color.appOrange.opacity(0.6))
                        }
                    } else {
                        Button {
                            HapticManager.shared.buttonTap()
                            showPaywall = true
                        } label: {
                            Label("Upgrade to Pro", systemImage: "sparkles")
                        }
                    }

                    Button {
                        HapticManager.shared.buttonTap()
                        Task { 
                            try? await store.restorePurchases()
                            if store.isProUser {
                                HapticManager.shared.sessionComplete()
                            }
                        }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }

                Section("About") {
                    LabeledContent {
                        Text(settings.appVersion)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Version", systemImage: "info.circle")
                    }
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Terms of Use", systemImage: "doc.text")
                    }
                }
            }
            .appThemedList()
            .tint(.appOrange)
            .navigationTitle("Settings")
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var themeBinding: Binding<String> {
        Binding(
            get: { settings.themeSelection },
            set: { newValue in
                if newValue == "dark" && !store.isProUser {
                    HapticManager.shared.buttonTap()
                    showPaywall = true
                } else {
                    HapticManager.shared.selection()
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
                    HapticManager.shared.buttonTap()
                    showPaywall = true
                } else {
                    HapticManager.shared.selection()
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
