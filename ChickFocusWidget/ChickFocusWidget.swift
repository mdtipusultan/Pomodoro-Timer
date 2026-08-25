import WidgetKit
import SwiftUI

struct WidgetSnapshot: Codable, Equatable {
    var todayMinutes: Int
    var streak: Int
    var weekHours: [Double]
    var sessionTitles: [String]
    var updatedAt: Date
}

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
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChickFocusWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> ChickFocusWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.office.PomodoroTimer") ?? .standard
        guard let data = defaults.data(forKey: "widgetSnapshot"),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return placeholder(in: .init())
        }
        return ChickFocusWidgetEntry(
            date: Date(),
            todayFocusMinutes: snapshot.todayMinutes,
            streak: snapshot.streak,
            weekHours: snapshot.weekHours,
            todaySessions: snapshot.sessionTitles.enumerated().map { index, title in
                WidgetSession(id: UUID(), tagName: title, duration: 0, time: Date())
            }
        )
    }
}

private let brandOrange = Color(red: 1.0, green: 0.55, blue: 0.18)

struct ChickFocusSmallWidget: View {
    let entry: ChickFocusWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "cat.fill")
                .font(.title)
                .foregroundStyle(brandOrange)
            Text("KittyFocus")
                .font(.caption.weight(.semibold))
                .foregroundStyle(brandOrange)
            Text("\(entry.todayFocusMinutes)m")
                .font(.title2.bold())
            Text("Today")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ChickFocusMediumWidget: View {
    let entry: ChickFocusWidgetEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("This Week")
                    .font(.headline)
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(Array(entry.weekHours.enumerated()), id: \.offset) { _, hours in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(brandOrange.gradient)
                            .frame(width: 12, height: max(6, hours * 30))
                    }
                }
            }
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(brandOrange)
                Text("\(entry.streak)")
                    .font(.title.bold())
                Text("streak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(4)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ChickFocusLargeWidget: View {
    let entry: ChickFocusWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "cat.fill")
                    .foregroundStyle(brandOrange)
                Text("Today's Sessions")
                    .font(.headline)
                Spacer()
                Text("\(entry.todayFocusMinutes)m")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(brandOrange)
            }

            if entry.todaySessions.isEmpty {
                Spacer()
                Text("No sessions yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.todaySessions) { session in
                    HStack {
                        Circle()
                            .fill(brandOrange)
                            .frame(width: 7, height: 7)
                        Text(session.tagName)
                        Spacer()
                        Text(session.duration.formattedHoursMinutes)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                Spacer()
            }
        }
        .padding(4)
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
        .configurationDisplayName("KittyFocus")
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
