import SwiftData
import SwiftUI

struct PetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var sessions: [FocusSession]

    let pet: Pet
    @State private var petName: String = ""
    @State private var petViewModel = PetViewModel()

    var session: FocusSession? {
        petViewModel.session(for: pet, sessions: sessions)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: pet.type.systemImage)
                    .font(.system(size: 80))
                    .foregroundStyle(pet.type.color)
                    .padding(.top, 32)

                TextField("Name your companion", text: $petName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 32)
                    .onSubmit {
                        petViewModel.updatePetName(pet, name: petName, context: modelContext)
                    }

                VStack(spacing: 12) {
                    detailRow("Raised", pet.raisedDate.formattedShortDate())
                    detailRow("Likability", "\(pet.likability)%")
                    if let session {
                        detailRow("Duration", session.actualDuration.formattedHoursMinutes)
                        if let tag = session.tag {
                            HStack {
                                Text("Tag")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                HStack(spacing: 6) {
                                    Circle().fill(Color(hex: tag.colorHex)).frame(width: 8, height: 8)
                                    Text(tag.name)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .navigationTitle(pet.type.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                petName = pet.name ?? ""
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
