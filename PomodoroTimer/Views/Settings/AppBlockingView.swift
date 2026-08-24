import SwiftUI

// FAMILY_CONTROLS_DISABLED — uncomment block below to re-enable Screen Time app blocking.
// #if canImport(FamilyControls)
// import FamilyControls
// #endif

struct AppBlockingView: View {
    // FAMILY_CONTROLS_DISABLED
    // @EnvironmentObject private var blockingService: AppBlockingService

    var body: some View {
        List {
            Section {
                Text("App blocking is temporarily disabled.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // FAMILY_CONTROLS_DISABLED
            // Section {
            //     Text("Select apps to block during focus sessions. Requires Screen Time permission.")
            //         .font(.subheadline)
            //         .foregroundStyle(.secondary)
            // }
            //
            // #if canImport(FamilyControls) && !targetEnvironment(simulator)
            // Section("Blocked Apps") {
            //     FamilyActivityPicker(selection: $blockingService.selection)
            //         .onChange(of: blockingService.selection) { _, _ in
            //             blockingService.persistSelection()
            //         }
            // }
            // #else
            // Section {
            //     Text("App blocking is not available in the simulator.")
            //         .foregroundStyle(.secondary)
            // }
            // #endif
            //
            // Section {
            //     if blockingService.isBlocking {
            //         Button("Stop Blocking", role: .destructive) {
            //             blockingService.stopBlocking()
            //         }
            //     } else {
            //         Button("Start Blocking") {
            //             blockingService.startBlocking()
            //         }
            //         .disabled(!blockingService.isAuthorized)
            //     }
            // }
        }
        .appThemedList()
        .tint(.appOrange)
        .navigationTitle("App Blocking")
        // FAMILY_CONTROLS_DISABLED
        // .task {
        //     if !blockingService.isAuthorized {
        //         isRequestingAuth = true
        //         await blockingService.requestAuthorization()
        //         isRequestingAuth = false
        //     }
        // }
    }
}

#Preview {
    NavigationStack {
        AppBlockingView()
            .environmentObject(AppBlockingService())
    }
}
