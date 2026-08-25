import SwiftUI

struct CompanionDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let resident: FarmResident
    let petViewModel: PetViewModel

    @State private var name = ""
    @State private var grown = false

    private let heroBase: CGFloat = 150

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    hero

                    if resident.hasArrived {
                        nameField
                        growthCard
                        statsCard
                    } else {
                        notArrivedCard
                    }

                    Spacer(minLength: 12)
                }
                .padding(.top, 12)
            }
            .appScreenBackground()
            .navigationTitle(resident.hasArrived ? petViewModel.name(for: resident.type) : resident.type.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        commitName()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                name = petViewModel.hasCustomName(for: resident.type)
                    ? petViewModel.name(for: resident.type)
                    : ""
                withAnimation(.spring(response: 0.7, dampingFraction: 0.62).delay(0.15)) {
                    grown = true
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(resident.type.color.opacity(0.16))
                    .frame(width: heroBase * 1.05, height: heroBase * 1.05)

                Image(resident.type.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: heroBase * resident.scale,
                        height: heroBase * resident.scale
                    )
                    .opacity(resident.hasArrived ? 1 : 0.25)
                    .grayscale(resident.hasArrived ? 0 : 1)
                    .scaleEffect(grown ? 1 : 0.62)
            }
            .frame(height: heroBase * 1.15)

            Text(resident.hasArrived ? resident.stage.title : "Not raised yet")
                .font(.headline)
                .foregroundStyle(resident.hasArrived ? Color.appOrange : .secondary)

            if resident.hasArrived {
                Text("\(resident.sizePercent)% of full size")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var nameField: some View {
        TextField(resident.type.displayName, text: $name)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(.body.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .appCardStyle(radius: 14)
            .padding(.horizontal, 24)
            .submitLabel(.done)
            .onSubmit(commitName)
    }

    // MARK: - Growth

    private var growthCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Growth")
                    .font(.subheadline.weight(.bold))

                Spacer()

                if let remaining = resident.sessionsToNextStage, let next = resident.stage.next {
                    Text(remaining == 0 ? "Ready to grow" : "\(remaining) to \(next.title)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Fully grown")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appOrange)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appFill)

                    Capsule()
                        .fill(Color.appOrangeGradient)
                        .frame(width: max(10, geometry.size.width * resident.stageProgress))
                }
            }
            .frame(height: 10)

            HStack(spacing: 0) {
                ForEach(GrowthStage.allCases) { stage in
                    VStack(spacing: 5) {
                        Circle()
                            .fill(stage.rawValue <= resident.stage.rawValue ? Color.appOrange : Color.appFill)
                            .frame(width: 9, height: 9)

                        Text(stage.title)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(
                                stage.rawValue <= resident.stage.rawValue ? Color.appOrange : .secondary
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .appCardStyle(radius: 16)
        .padding(.horizontal, 24)
    }

    // MARK: - Stats

    private var statsCard: some View {
        VStack(spacing: 0) {
            statRow("Sessions completed", "\(resident.sessions)")
            Divider()
            statRow("Total focus", resident.totalFocus.formattedHoursMinutes)
            Divider()
            statRow("Sessions today", "\(resident.raisedToday)")
            Divider()
            statRow("Best likability", "\(resident.bestLikability)%")

            if let first = resident.firstRaised {
                Divider()
                statRow("First arrived", first.formattedShortDate())
            }

            if let last = resident.lastRaised {
                Divider()
                statRow("Last session", last.formattedShortDate())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .appCardStyle(radius: 16)
        .padding(.horizontal, 24)
    }

    private var notArrivedCard: some View {
        VStack(spacing: 10) {
            Text("Bring this companion home")
                .font(.subheadline.weight(.bold))

            Text("Pick the \(resident.type.displayName.lowercased()) on the Focus tab, then finish a session. Every session after that makes it grow bigger.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .appCardStyle(radius: 16)
        .padding(.horizontal, 24)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(.vertical, 11)
    }

    private func commitName() {
        petViewModel.setName(name, for: resident.type)
    }
}
