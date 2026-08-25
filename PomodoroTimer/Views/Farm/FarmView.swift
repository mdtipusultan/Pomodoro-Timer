import SwiftData
import SwiftUI

enum FarmViewMode: String, CaseIterable, Identifiable {
    case pasture
    case collection

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pasture: return "Pasture"
        case .collection: return "Collection"
        }
    }

    var systemImage: String {
        switch self {
        case .pasture: return "leaf.fill"
        case .collection: return "square.grid.2x2.fill"
        }
    }
}

struct FarmView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Pet.raisedDate, order: .reverse) private var pets: [Pet]
    @State private var petViewModel = PetViewModel()
    @State private var selectedPet: Pet?
    @AppStorage("farmViewMode") private var storedMode = FarmViewMode.pasture.rawValue

    private var mode: FarmViewMode {
        FarmViewMode(rawValue: storedMode) ?? .pasture
    }

    private var modeBinding: Binding<FarmViewMode> {
        Binding(get: { mode }, set: { storedMode = $0.rawValue })
    }

    private var columns: Int {
        horizontalSizeClass == .regular ? 5 : 3
    }

    private var stats: FarmStats {
        petViewModel.stats(for: pets)
    }

    private var visiblePets: [Pet] {
        Array(pets.prefix(FarmLayout.maxVisible))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                switch mode {
                case .pasture:
                    pastureScene
                case .collection:
                    collectionGrid
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Farm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("View", selection: modeBinding) {
                            ForEach(FarmViewMode.allCases) { option in
                                Label(option.label, systemImage: option.systemImage)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: mode.systemImage)
                    }
                }
            }
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

    // MARK: - Pasture

    private var pastureScene: some View {
        VStack(spacing: 0) {
            FarmSkyView()

            VStack(spacing: 0) {
                FarmSignboardView(stats: stats)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                if pets.isEmpty {
                    emptyPasture
                } else {
                    pastureField
                }

                pastureFooter
            }
            .background(
                LinearGradient(
                    colors: [.farmGrassLight, .farmGrassDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var pastureField: some View {
        let animals = visiblePets
        let rowCount = FarmLayout.rows(count: animals.count, columns: columns)
        let fieldHeight = FarmLayout.height(count: animals.count, columns: columns)

        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(FarmLayout.decorations(rows: rowCount)) { decoration in
                    decorationView(decoration)
                        .position(
                            x: geometry.size.width * decoration.x,
                            y: fieldHeight * decoration.y
                        )
                }

                ForEach(Array(animals.enumerated()), id: \.element.id) { index, pet in
                    let spot = FarmLayout.spot(index: index, seed: pet.id, columns: columns)

                    FarmAnimalView(
                        pet: pet,
                        spot: spot,
                        isNew: Calendar.current.isDateInToday(pet.raisedDate),
                        entranceDelay: min(Double(index) * 0.035, 0.9)
                    ) {
                        HapticManager.shared.petInteraction()
                        selectedPet = pet
                    }
                    .position(x: geometry.size.width * spot.x, y: spot.y)
                }
            }
            .frame(width: geometry.size.width, height: fieldHeight, alignment: .topLeading)
        }
        .frame(height: fieldHeight)
    }

    @ViewBuilder
    private func decorationView(_ decoration: FarmLayout.Decoration) -> some View {
        switch decoration.kind {
        case .grass:
            FarmGrassTuftView(scale: decoration.scale)
        case .flower:
            FarmFlowerView(scale: decoration.scale)
        case .stone:
            Ellipse()
                .fill(Color.farmWoodDark.opacity(0.35))
                .frame(width: 13 * decoration.scale, height: 8 * decoration.scale)
        }
    }

    private var emptyPasture: some View {
        VStack(spacing: 16) {
            Image("EmptyFarm")
                .resizable()
                .scaledToFit()
                .frame(width: 190, height: 190)

            Text("Your pasture is waiting")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text("Finish a focus session and your first companion moves in. The longer you focus, the more animals fill the farm.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 36)
        }
        .padding(.top, 22)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your pasture is waiting. Finish a focus session to raise your first companion.")
    }

    private var pastureFooter: some View {
        VStack(spacing: 12) {
            levelCard

            if pets.count > FarmLayout.maxVisible {
                Button {
                    storedMode = FarmViewMode.collection.rawValue
                } label: {
                    Text("\(pets.count - FarmLayout.maxVisible) more resting in the barn")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.farmWoodDark.opacity(0.8), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Text("Every completed session brings one new animal home.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 28)
    }

    private var levelCard: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Farm level \(stats.level)", systemImage: "leaf.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(stats.animalsToNextLevel) to level \(stats.level + 1)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.22))

                    Capsule()
                        .fill(Color.appOrangeGradient)
                        .frame(width: max(8, geometry.size.width * stats.progress))
                }
            }
            .frame(height: 9)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.farmWoodDark.opacity(0.78))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Farm level \(stats.level). \(stats.animalsToNextLevel) animals until level \(stats.level + 1).")
    }

    // MARK: - Collection

    private var collectionGrid: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 12),
                count: columns
            ),
            spacing: 12
        ) {
            ForEach(petViewModel.petsSorted(pets), id: \.id) { pet in
                Button {
                    HapticManager.shared.petInteraction()
                    selectedPet = pet
                } label: {
                    collectionCard(pet)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .overlay {
            if pets.isEmpty {
                Text("No companions yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 60)
            }
        }
    }

    private func collectionCard(_ pet: Pet) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(pet.type.color.opacity(0.14))
                    .frame(width: 66, height: 66)

                Image(pet.type.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
            }

            Text(pet.name ?? pet.type.displayName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.primary)

            Text(pet.raisedDate.formattedShortDate())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .appCardStyle(radius: 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pet.name ?? pet.type.displayName), raised on \(pet.raisedDate.formattedShortDate())")
        .accessibilityHint("Double tap to view details")
    }
}

// MARK: - Signboard

struct FarmSignboardView: View {
    let stats: FarmStats

    var body: some View {
        HStack(spacing: 0) {
            item(value: stats.total, label: "Animals")
            separator
            item(value: stats.today, label: "Today")
            separator
            item(value: stats.species, label: "Species")
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.farmWood, .farmWoodDark],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.farmWoodDark, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stats.total) animals, \(stats.today) raised today, \(stats.species) species")
    }

    private func item(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity)
    }

    private var separator: some View {
        Rectangle()
            .fill(.white.opacity(0.22))
            .frame(width: 1, height: 26)
    }
}

#Preview {
    FarmView()
        .modelContainer(for: [Pet.self, FocusSession.self, Tag.self], inMemory: true)
}
