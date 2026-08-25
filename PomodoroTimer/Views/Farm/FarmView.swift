import SwiftData
import SwiftUI

struct FarmView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Pet.raisedDate, order: .reverse) private var pets: [Pet]
    @Query private var sessions: [FocusSession]
    @State private var petViewModel = PetViewModel()
    @State private var selectedType: PetType?

    private var residents: [FarmResident] {
        petViewModel.residents(pets: pets, sessions: sessions)
    }

    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let residents = residents
                let stats = petViewModel.stats(for: residents)

                VStack(spacing: 0) {
                    FarmSkyView()

                    VStack(spacing: 0) {
                        FarmSignboardView(stats: stats)
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(residents) { resident in
                                FarmResidentView(
                                    resident: resident,
                                    name: petViewModel.name(for: resident.type)
                                ) {
                                    HapticManager.shared.petInteraction()
                                    selectedType = resident.type
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 18)

                        footer(stats: stats)
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
            .background {
                VStack(spacing: 0) {
                    Color.farmSkyTop
                    Color.farmGrassDeep
                }
                .ignoresSafeArea()
            }
            .navigationTitle("Farm")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedType) { type in
                CompanionDetailView(
                    resident: residents.first { $0.type == type }
                        ?? FarmResident(
                            type: type,
                            sessions: 0,
                            totalFocus: 0,
                            firstRaised: nil,
                            lastRaised: nil,
                            bestLikability: 0,
                            raisedToday: 0
                        ),
                    petViewModel: petViewModel
                )
            }
        }
    }

    private func footer(stats: FarmStats) -> some View {
        VStack(spacing: 12) {
            levelCard(stats: stats)

            Text("Every completed session feeds your companion and makes it grow.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 28)
    }

    private func levelCard(stats: FarmStats) -> some View {
        VStack(spacing: 10) {
            HStack {
                Label("Farm level \(stats.level)", systemImage: "leaf.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(stats.sessionsToNextLevel) to level \(stats.level + 1)")
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
        .accessibilityLabel("Farm level \(stats.level). \(stats.sessionsToNextLevel) sessions until level \(stats.level + 1).")
    }
}

// MARK: - Signboard

struct FarmSignboardView: View {
    let stats: FarmStats

    var body: some View {
        HStack(spacing: 0) {
            item(value: "\(stats.arrived)/\(PetType.allCases.count)", label: "Animals")
            separator
            item(value: "\(stats.today)", label: "Today")
            separator
            item(value: "\(stats.totalSessions)", label: "Sessions")
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
        .accessibilityLabel("\(stats.arrived) of \(PetType.allCases.count) animals raised, \(stats.today) sessions today, \(stats.totalSessions) sessions total")
    }

    private func item(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
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

extension PetType: Identifiable {
    public var id: String { rawValue }
}

#Preview {
    FarmView()
        .modelContainer(for: [Pet.self, FocusSession.self, Tag.self], inMemory: true)
}
