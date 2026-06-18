import SwiftUI

enum PetType: String, Codable, CaseIterable {
    case cat, bird, hare, fish, ladybug, tortoise

    var systemImage: String {
        switch self {
        case .cat: return "cat.fill"
        case .bird: return "bird.fill"
        case .hare: return "hare.fill"
        case .fish: return "fish.fill"
        case .ladybug: return "ladybug.fill"
        case .tortoise: return "tortoise.fill"
        }
    }

    var color: Color {
        switch self {
        case .cat: return .orange
        case .bird: return .blue
        case .hare: return .pink
        case .fish: return .cyan
        case .ladybug: return .red
        case .tortoise: return .green
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    var isLocked: Bool {
        self != .cat
    }

    var productID: String? {
        switch self {
        case .cat: return nil
        case .bird: return "com.chickfocus.pet.bird"
        case .hare: return "com.chickfocus.pet.hare"
        case .fish: return "com.chickfocus.pet.fish"
        case .ladybug: return nil
        case .tortoise: return nil
        }
    }
}
