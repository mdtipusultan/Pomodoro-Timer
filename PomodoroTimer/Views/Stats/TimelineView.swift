import SwiftUI

struct TimelineView: View {
    let groups: [StatsViewModel.DayGroup]
    let use24Hour: Bool
    let isPro: Bool
    let onDelete: (FocusSession) -> Void
  let onShowPaywall: () -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
            ForEach(groups) { group in
                Section {
                    ForEach(group.sessions, id: \.id) { session in
                        SessionRowView(
                            session: session,
                            use24Hour: use24Hour,
                            note: .constant(session.note ?? ""),
                            onNoteCommit: {}
                        )
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if isPro {
                                    onDelete(session)
                                } else {
                                    onShowPaywall()
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(group.date.formattedShortDate())
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}
