import SwiftData
import SwiftUI

struct FarmView: View {
    @Query(sort: \Pet.raisedDate, order: .reverse) private var pets: [Pet]
    @State private var petViewModel = PetViewModel()
    @State private var selectedPet: Pet?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if pets.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(petViewModel.petsSorted(pets), id: \.id) { pet in
                                Button {
                                    selectedPet = pet
                                } label: {
                                    petCard(pet)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .appScreenBackground()
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

    private func petCard(_ pet: Pet) -> some View {
        VStack(spacing: 10) {
            Image(pet.type.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 62, height: 62)

            Text(pet.name ?? pet.type.displayName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.primary)

            Text(pet.raisedDate.formattedShortDate())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .appCardStyle(radius: 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pet.name ?? pet.type.displayName), raised on \(pet.raisedDate.formattedShortDate())")
        .accessibilityHint("Double tap to view details")
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.appOrange.opacity(0.12))
                    .frame(width: 140, height: 140)
                    .blur(radius: 16)
                
                Circle()
                    .fill(Color.appOrange.opacity(0.14))
                    .frame(width: 130, height: 130)
                
                Image("EmptyFarm")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }

            VStack(spacing: 12) {
                Text("Your farm is empty")
                    .font(.title2.bold())

                Text("Complete a \(AppBrand.name) session to grow your first companion. Each successful session brings a new friend to your farm!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your farm is empty. Complete a \(AppBrand.name) session to grow your first companion.")
    }
}

#Preview {
    FarmView()
}
