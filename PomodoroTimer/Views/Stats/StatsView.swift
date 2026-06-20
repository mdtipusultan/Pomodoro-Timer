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
                .padding()
            }
            .background(Color.appBackground)
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
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
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
                    icon: "sun.max.fill"
                )
                StatCard(
                    title: "This Week",
                    value: viewModel.weekFocusTime(sessions).formattedHoursMinutes,
                    icon: "calendar"
                )
                StatCard(
                    title: "Streak",
                    value: "\(viewModel.currentStreak(sessions)) days",
                    icon: "flame.fill"
                )
                StatCard(
                    title: "Sessions",
                    value: "\(viewModel.totalCompletedSessions(sessions))",
                    icon: "checkmark.circle.fill"
                )
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                .cornerRadius(4)
            }
            .frame(height: 200)
            .animation(.spring, value: viewModel.selectedPeriod)
        }
        .padding()
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)

            if !store.isProUser {
                Text("Showing last 7 days. Upgrade to Pro for full history.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if timelineGroups.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(Color.appSecondary)
                    Text("No sessions yet")
                        .font(.headline)
                    Text("Complete a focus session and it will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.appOrange)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(width: 120, alignment: .leading)
        .padding()
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
