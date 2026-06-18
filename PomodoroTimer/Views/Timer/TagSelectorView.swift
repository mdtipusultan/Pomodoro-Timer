import SwiftData
import SwiftUI

struct TagSelectorView: View {
  @Binding var selectedTag: Tag?
    let tags: [Tag]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.id) { tag in
                    Button {
                        selectedTag = tag
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: tag.colorHex))
                                .frame(width: 8, height: 8)
                            Text(tag.name)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedTag?.id == tag.id
                                ? Color(hex: tag.colorHex).opacity(0.2)
                                : Color.appSurface
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedTag?.id == tag.id ? Color(hex: tag.colorHex) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
