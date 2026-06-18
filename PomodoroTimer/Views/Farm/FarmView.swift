import SwiftData
import SwiftUI

struct FarmView: View {
    @Query(sort: \Pet.raisedDate, order: .reverse) private var pets: [Pet]
    @State private var petViewModel = PetViewModel()
    @State private var selectedPet: Pet?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            Group {
                if pets.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(petViewModel.petsSorted(pets), id: \.id) { pet in
                                Button {
                                    selectedPet = pet
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: pet.type.systemImage)
                                            .font(.system(size: 40))
                                            .foregroundStyle(pet.type.color)
                                        Text(pet.raisedDate.formattedShortDate())
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.appSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Farm")
            .sheet(isPresented: Binding(
                get: { selectedPet != nil },
                set: { if !$0 { selectedPet = nil } }
            )) {
                if let selectedPet {
                    PetDetailView(pet: selectedPet)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cat.fill")
                .font(.system(size: 60))
                //.foregroundStyle(Color.appOrange.opacity(0.5))
            Text("Complete a focus session to grow your first companion!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    FarmView()
}
