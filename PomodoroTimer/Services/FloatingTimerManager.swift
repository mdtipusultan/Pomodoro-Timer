import Combine
import SwiftUI
import UIKit

@MainActor
final class FloatingTimerManager: ObservableObject {
    static let shared = FloatingTimerManager()

    private var floatingWindow: UIWindow?
    @Published var isVisible = false

    private init() {}

    func show(timeRemaining: TimeInterval, petType: PetType, onTap: @escaping () -> Void) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundInactive || $0.activationState == .background })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let hosting = UIHostingController(
            rootView: FloatingTimerContent(
                timeRemaining: timeRemaining,
                petType: petType,
                onTap: onTap
            )
        )
        hosting.view.backgroundColor = .clear
        window.rootViewController = hosting
        window.isHidden = false
        floatingWindow = window
        isVisible = true
    }

    func hide() {
        floatingWindow?.isHidden = true
        floatingWindow = nil
        isVisible = false
    }

    func update(timeRemaining: TimeInterval) {
        guard let hosting = floatingWindow?.rootViewController as? UIHostingController<FloatingTimerContent> else { return }
        // Re-create with updated time via notification
        NotificationCenter.default.post(
            name: .floatingTimerUpdate,
            object: nil,
            userInfo: ["timeRemaining": timeRemaining]
        )
    }
}

extension Notification.Name {
    static let floatingTimerUpdate = Notification.Name("floatingTimerUpdate")
}

struct FloatingTimerContent: View {
    let timeRemaining: TimeInterval
    let petType: PetType
    let onTap: () -> Void

    @State private var displayTime: TimeInterval
    @State private var dragOffset = CGSize.zero

    init(timeRemaining: TimeInterval, petType: PetType, onTap: @escaping () -> Void) {
        self.timeRemaining = timeRemaining
        self.petType = petType
        self.onTap = onTap
        _displayTime = State(initialValue: timeRemaining)
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: petType.systemImage)
                .font(.title3)
                .foregroundStyle(Color.appOrange)
            Text(displayTime.formattedTimer)
                .font(.caption.bold().monospacedDigit())
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { dragOffset = $0.translation }
        )
        .onTapGesture(perform: onTap)
        .onReceive(NotificationCenter.default.publisher(for: .floatingTimerUpdate)) { notification in
            if let time = notification.userInfo?["timeRemaining"] as? TimeInterval {
                displayTime = time
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding()
    }
}
