import WidgetKit
import SwiftUI

struct ChickFocusWidgetEntry: TimelineEntry {
    let date: Date
    let todayFocusMinutes: Int
    let streak: Int
    let weekHours: [Double]
    let todaySessions: [WidgetSession]
}

struct WidgetSession: Identifiable {
    let id: UUID
    let tagName: String
    let duration: TimeInterval
    let time: Date
}

struct ChickFocusWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChickFocusWidgetEntry {
        ChickFocusWidgetEntry(
            date: Date(),
            todayFocusMinutes: 75,
            streak: 3,
            weekHours: [1.2, 0.5, 2.0, 1.5, 0.8, 1.0, 0.3],
            todaySessions: [
                WidgetSession(id: UUID(), tagName: "Work", duration: 1500, time: Date())
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ChickFocusWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChickFocusWidgetEntry>) -> Void) {
        let entry = placeholder(in: context)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct ChickFocusSmallWidget: View {
    let entry: ChickFocusWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "cat.fill")
                .font(.title)
                .foregroundStyle(.orange)
            Text("\(entry.todayFocusMinutes)m")
                .font(.title2.bold())
            Text("Today")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ChickFocusMediumWidget: View {
    let entry: ChickFocusWidgetEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("This Week")
                    .font(.headline)
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(entry.weekHours.enumerated()), id: \.offset) { _, hours in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.orange)
                            .frame(width: 12, height: max(4, hours * 30))
                    }
                }
            }
            Spacer()
            VStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(entry.streak)")
                    .font(.title.bold())
                Text("streak")
                    .font(.caption2)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ChickFocusLargeWidget: View {
    let entry: ChickFocusWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Sessions")
                .font(.headline)
            ForEach(entry.todaySessions) { session in
                HStack {
                    Text(session.tagName)
                    Spacer()
                    Text(session.duration.formattedHoursMinutes)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct ChickFocusWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChickFocusWidget()
    }
}

struct ChickFocusWidget: Widget {
    let kind = "ChickFocusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChickFocusWidgetProvider()) { entry in
            ChickFocusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ChickFocus")
        .description("Track your focus time and streak.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ChickFocusWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ChickFocusWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            ChickFocusSmallWidget(entry: entry)
        case .systemMedium:
            ChickFocusMediumWidget(entry: entry)
        case .systemLarge:
            ChickFocusLargeWidget(entry: entry)
        default:
            ChickFocusSmallWidget(entry: entry)
        }
    }
}

private extension TimeInterval {
    var formattedHoursMinutes: String {
        let total = max(0, Int(self))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
