import ActivityKit
import Foundation

struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var sessionType: String
        var tagName: String?
        var progress: Double
    }

    var petType: String
}

@MainActor
final class LiveActivityService {
    private var currentActivity: Activity<FocusActivityAttributes>?

    func start(petType: PetType, tagName: String?, timeRemaining: TimeInterval, totalDuration: TimeInterval, sessionType: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        end()

        let attributes = FocusActivityAttributes(petType: petType.rawValue)
        let state = FocusActivityAttributes.ContentState(
            timeRemaining: timeRemaining,
            sessionType: sessionType,
            tagName: tagName,
            progress: totalDuration > 0 ? 1 - (timeRemaining / totalDuration) : 0
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {}
    }

    func update(timeRemaining: TimeInterval, totalDuration: TimeInterval, sessionType: String, tagName: String?) {
        guard let activity = currentActivity else { return }
        let state = FocusActivityAttributes.ContentState(
            timeRemaining: timeRemaining,
            sessionType: sessionType,
            tagName: tagName,
            progress: totalDuration > 0 ? 1 - (timeRemaining / totalDuration) : 0
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    func end() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}
