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

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(session.tag?.name ?? "Untagged")
                        .font(.subheadline.weight(.semibold))
                    if session.isManuallyAdded {
                        Text("Manual")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appFill, in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                }
                Text(session.startDate.formattedTime(use24Hour: use24Hour))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(session.actualDuration.formattedHoursMinutes)
                    .font(.subheadline.weight(.medium).monospacedDigit())
                statusLabel
            }
        }
        .padding(14)
        .appCardStyle(radius: AppRadius.compact)
    }

    @ViewBuilder
    private var statusLabel: some View {
        if session.wasSuccessful {
            Label("Done", systemImage: "checkmark.circle.fill")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.breakGreen)
        } else if session.isFailed {
            Label("Failed", systemImage: "xmark.circle.fill")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.dangerRed)
        }
    }
}
