import SwiftData
import SwiftUI

struct TagManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]

    @State private var newName = ""
    @State private var newColor = "FF9500"

    private let colors = ["FF9500", "5856D6", "34C759", "FF2D55", "007AFF", "AF52DE", "FFCC00", "64D2FF"]

    var body: some View {
        NavigationStack {
            List {
                Section("Add tag") {
                    TextField("Name", text: $newName)
                    HStack(spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if newColor == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { newColor = hex }
                        }
                    }
                    Button("Add Tag") {
                        let name = newName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        modelContext.insert(Tag(name: name, colorHex: newColor, sortOrder: tags.count))
                        try? modelContext.save()
                        newName = ""
                        HapticManager.shared.buttonTap()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Section("Your tags") {
                    ForEach(tags, id: \.id) { tag in
                        HStack {
                            Circle()
                                .fill(Color(hex: tag.colorHex))
                                .frame(width: 12, height: 12)
                            TextField("Tag name", text: Binding(
                                get: { tag.name },
                                set: { tag.name = $0 }
                            ))
                            .onSubmit { try? modelContext.save() }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(tags[index])
                        }
                        try? modelContext.save()
                    }
                }
            }
            .appThemedList()
            .navigationTitle("Tags")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
