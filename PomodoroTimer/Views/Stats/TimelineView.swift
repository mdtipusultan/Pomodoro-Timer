import SwiftUI

struct TimelineView: View {
    let groups: [StatsViewModel.DayGroup]
    let use24Hour: Bool
    let isPro: Bool
    let onDelete: (FocusSession) -> Void
    let onShowPaywall: () -> Void
    var onEdit: ((FocusSession) -> Void)? = nil

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
            ForEach(groups) { group in
                Section {
                    ForEach(group.sessions, id: \.id) { session in
                        Button {
                            onEdit?(session)
                        } label: {
                            SessionRowView(
                                session: session,
                                use24Hour: use24Hour,
                                note: .constant(session.note ?? ""),
                                onNoteCommit: {}
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
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
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                        .background(Color.appBackground)
                }
            }
        }
    }
}
