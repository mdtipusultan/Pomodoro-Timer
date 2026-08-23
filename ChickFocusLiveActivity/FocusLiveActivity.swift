import ActivityKit
import SwiftUI
import WidgetKit

struct FocusLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            HStack(spacing: 16) {
                Image(systemName: PetType(rawValue: context.attributes.petType)?.systemImage ?? "cat.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.18))
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.sessionType)
                        .font(.headline)
                    if let tag = context.state.tagName {
                        Text(tag)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(context.state.timeRemaining.formattedTimer)
                    .font(.title2.bold().monospacedDigit())
                    .monospacedDigit()
            }
            .padding()
            .activityBackgroundTint(Color(red: 1.0, green: 0.55, blue: 0.18).opacity(0.16))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: PetType(rawValue: context.attributes.petType)?.systemImage ?? "cat.fill")
                        .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.18))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.timeRemaining.formattedTimer)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(Color(red: 1.0, green: 0.55, blue: 0.18))
                }
            } compactLeading: {
                Image(systemName: "cat.fill")
                    .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.18))
            } compactTrailing: {
                Text(context.state.timeRemaining.formattedTimer)
                    .monospacedDigit()
                    .font(.caption2)
            } minimal: {
                Image(systemName: "cat.fill")
                    .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.18))
            }
        }
    }
}

private extension TimeInterval {
    var formattedTimer: String {
        let total = max(0, Int(self))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

@main
struct FocusLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        FocusLiveActivityWidget()
    }
}
