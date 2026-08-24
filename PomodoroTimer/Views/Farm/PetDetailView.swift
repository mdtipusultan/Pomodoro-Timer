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
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(pet.type.color.opacity(0.16))
                                .frame(width: 128, height: 128)
                            Image(pet.type.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                        }

                        Text(pet.type.displayName)
                            .font(.title2.bold())
                    }
                    .padding(.top, 12)

                    TextField("Name your companion", text: $petName)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .appCardStyle(radius: 14)
                        .padding(.horizontal, 24)
                        .onSubmit {
                            petViewModel.updatePetName(pet, name: petName, context: modelContext)
                        }

                    VStack(spacing: 0) {
                        detailRow("Raised", pet.raisedDate.formattedShortDate())
                        Divider().padding(.leading, 4)
                        detailRow("Likability", "\(pet.likability)%")
                        if let session {
                            Divider().padding(.leading, 4)
                            detailRow("Duration", session.actualDuration.formattedHoursMinutes)
                            if let tag = session.tag {
                                Divider().padding(.leading, 4)
                                HStack {
                                    Text("Tag")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(hex: tag.colorHex))
                                            .frame(width: 8, height: 8)
                                        Text(tag.name)
                                    }
                                }
                                .padding(.vertical, 10)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .appCardStyle(radius: 16)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 16)
                }
            }
            .appScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        petViewModel.updatePetName(pet, name: petName, context: modelContext)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                petName = pet.name ?? ""
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .padding(.vertical, 10)
    }
}
