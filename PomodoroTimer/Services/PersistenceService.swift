import Foundation
import SwiftData

@MainActor
enum PersistenceService {
    static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema([FocusSession.self, Pet.self, Tag.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func seedDefaultTagsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Tag>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for (index, tag) in Tag.defaultTags.enumerated() {
            context.insert(Tag(name: tag.0, colorHex: tag.1, sortOrder: index))
        }
        try? context.save()
    }
}
