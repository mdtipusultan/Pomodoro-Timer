import SwiftUI

struct SessionRowView: View {
    let session: FocusSession
    let use24Hour: Bool
    @Binding var note: String
    let onNoteCommit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: session.tag?.colorHex ?? "FF9500"))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.tag?.name ?? "Untagged")
                    .font(.subheadline.weight(.medium))
                Text(session.startDate.formattedTime(use24Hour: use24Hour))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(session.actualDuration.formattedHoursMinutes)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
