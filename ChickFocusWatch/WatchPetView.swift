import SwiftUI

struct WatchPetView: View {
    let pets: [(type: PetType, date: Date, duration: TimeInterval)]

    var body: some View {
        List(pets, id: \.date) { pet in
            HStack {
                Image(systemName: pet.type.systemImage)
                    .foregroundStyle(pet.type.color)
                VStack(alignment: .leading) {
                    Text(pet.type.displayName)
                        .font(.headline)
                    Text(pet.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(pet.duration.formattedMinutes)
                    .font(.caption)
            }
        }
        .navigationTitle("Farm")
    }
}

private extension TimeInterval {
    var formattedMinutes: String {
        "\(max(0, Int(self)) / 60)m"
    }
}

#Preview {
    WatchPetView(pets: [
        (.cat, Date(), 1500),
        (.bird, Date().addingTimeInterval(-86400), 1500)
    ])
}
