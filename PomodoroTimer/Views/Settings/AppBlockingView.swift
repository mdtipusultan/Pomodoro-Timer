import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct AppBlockingView: View {
    @EnvironmentObject private var blockingService: AppBlockingService
    @State private var isRequestingAuth = false

    var body: some View {
        List {
            Section {
                Text("Select apps to block during focus sessions. Requires Screen Time permission.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            #if canImport(FamilyControls) && !targetEnvironment(simulator)
            Section("Blocked Apps") {
                FamilyActivityPicker(selection: $blockingService.selection)
            }
            #else
            Section {
                Text("App blocking is not available in the simulator.")
                    .foregroundStyle(.secondary)
            }
            #endif

            Section {
                if blockingService.isBlocking {
                    Button("Stop Blocking", role: .destructive) {
                        blockingService.stopBlocking()
                    }
                } else {
                    Button("Start Blocking") {
                        blockingService.startBlocking()
                    }
                    .disabled(!blockingService.isAuthorized)
                }
            }
        }
        .navigationTitle("App Blocking")
        .task {
            if !blockingService.isAuthorized {
                isRequestingAuth = true
                await blockingService.requestAuthorization()
                isRequestingAuth = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppBlockingView()
            .environmentObject(AppBlockingService())
    }
}
