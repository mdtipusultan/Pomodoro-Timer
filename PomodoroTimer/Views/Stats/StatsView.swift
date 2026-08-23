import Charts
import SwiftData
import SwiftUI

struct StatsView: View {
    @Environment(StoreKitService.self) private var store
    @Environment(SettingsViewModel.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSession.startDate, order: .reverse) private var sessions: [FocusSession]
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]

    @State private var viewModel = StatsViewModel()
    @State private var showPaywall = false
    @State private var showManualAdd = false

    private var timelineGroups: [StatsViewModel.DayGroup] {
        viewModel.groupedSessions(sessions, isPro: store.isProUser)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerCards
                    chartSection
                    timelineSection
                }
                .padding(16)
            }
            .appScreenBackground()
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if store.isProUser {
                            showManualAdd = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.appOrange)
                    }
                }
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showManualAdd) {
                ManualSessionSheet(tags: tags) { start, duration, tag, note in
                    viewModel.addManualSession(
                        startDate: start,
                        duration: duration,
                        tag: tag,
                        note: note,
                        context: modelContext
                    )
                }
            }
            .onAppear { syncSettings() }
            .onChange(of: settings.nightOwlMode) { _, _ in syncSettings() }
            .onChange(of: settings.weekStartsOnMonday) { _, _ in syncSettings() }
        }
    }

    private func syncSettings() {
        viewModel.nightOwlMode = settings.nightOwlMode
        viewModel.weekStartsOnMonday = settings.weekStartsOnMonday
    }

    private var headerCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Today",
                    value: viewModel.todayFocusTime(sessions).formattedHoursMinutes,
                    icon: "sun.max.fill",
                    tint: .appOrange
                )
                StatCard(
                    title: "This Week",
                    value: viewModel.weekFocusTime(sessions).formattedHoursMinutes,
                    icon: "calendar",
                    tint: .blue
                )
                StatCard(
                    title: "Streak",
                    value: "\(viewModel.currentStreak(sessions)) days",
                    icon: "flame.fill",
                    tint: .pink
                )
                StatCard(
                    title: "Sessions",
                    value: "\(viewModel.totalCompletedSessions(sessions))",
                    icon: "checkmark.circle.fill",
                    tint: .breakGreen
                )
            }
            .padding(.horizontal, 16)
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Period", selection: $viewModel.selectedPeriod) {
                ForEach(StatsViewModel.ChartPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)

            Chart(viewModel.chartData(from: sessions, isPro: store.isProUser)) { point in
                BarMark(
                    x: .value("Label", point.label),
                    y: .value("Hours", point.hours)
                )
                .foregroundStyle(Color.appOrange.gradient)
                .cornerRadius(7)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 220)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedPeriod)
        }
        .padding(18)
        .appCardStyle()
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("History")
                .font(.title3.bold())

            if !store.isProUser {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    Text("Showing last 7 days. Upgrade to Pro for full history.")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            if timelineGroups.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.appOrange.opacity(0.12))
                            .frame(width: 80, height: 80)
                            .blur(radius: 12)
                        
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.appOrange)
                            .symbolEffect(.pulse, options: .repeating)
                    }
                    
                    VStack(spacing: 8) {
                        Text("No sessions yet")
                            .font(.headline)
                        Text("Complete a focus session and it will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .appCardStyle()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No focus sessions recorded yet")
            } else {
                TimelineView(
                    groups: timelineGroups,
                    use24Hour: settings.use24HourTime,
                    isPro: store.isProUser,
                    onDelete: { session in
                        viewModel.deleteSession(session, context: modelContext)
                    },
                    onShowPaywall: { showPaywall = true }
                )
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                Text(value)
                    .font(.title3.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(width: 130, alignment: .leading)
        .padding(16)
        .appCardStyle(radius: 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

private struct ManualSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let tags: [Tag]
    let onSave: (Date, TimeInterval, Tag?, String?) -> Void

    @State private var startDate = Date()
    @State private var durationMinutes = 25
    @State private var selectedTag: Tag?
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Start", selection: $startDate)
                Stepper("Duration: \(durationMinutes) min", value: $durationMinutes, in: 1...180)
                Picker("Tag", selection: $selectedTag) {
                    Text("None").tag(nil as Tag?)
                    ForEach(tags, id: \.id) { tag in
                        Text(tag.name).tag(tag as Tag?)
                    }
                }
                TextField("Note", text: $note)
            }
            .navigationTitle("Add Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(startDate, TimeInterval(durationMinutes * 60), selectedTag, note.isEmpty ? nil : note)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    StatsView()
        .environment(StoreKitService())
        .environment(SettingsViewModel())
}
