import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TimerView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }
                .tag(0)

            FarmView()
                .tabItem {
                    Label("Farm", systemImage: "house.fill")
                }
                .badge(appState.unviewedPetCount > 0 ? appState.unviewedPetCount : 0)
                .tag(1)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.appOrange)
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 1 {
                appState.markPetsViewed()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
        .environment(TimerService())
        .environment(SoundService())
        .environment(StoreKitService())
        .environment(SettingsViewModel())
}
