import SwiftData
import SwiftUI

struct SessionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let session: FocusSession
    let isPro: Bool
    let onSave: (String?, TimeInterval?) -> Void
    let onPaywall: () -> Void

    @State private var note: String = ""
    @State private var durationMinutes: Int = 25

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextField("What did you focus on?", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Duration") {
                    Stepper("\(durationMinutes) min", value: $durationMinutes, in: 1...180)
                }
            }
            .navigationTitle("Edit Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isPro {
                            onSave(note, TimeInterval(durationMinutes * 60))
                            dismiss()
                        } else {
                            onPaywall()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                note = session.note ?? ""
                durationMinutes = max(1, Int(session.actualDuration / 60))
            }
        }
        .presentationDetents([.medium])
    }
}
