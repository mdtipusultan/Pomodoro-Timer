import SwiftData
import SwiftUI

struct TagSelectorView: View {
    @Binding var selectedTag: Tag?
    let tags: [Tag]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tags.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.id) { tag in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTag = tag
                        }
                        HapticManager.shared.selection()
                    } label: {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(Color(hex: tag.colorHex))
                                .frame(width: 9, height: 9)
                            Text(tag.name)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selectedTag?.id == tag.id
                                ? Color(hex: tag.colorHex).opacity(0.16)
                                : Color.appSurface,
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedTag?.id == tag.id
                                        ? Color(hex: tag.colorHex).opacity(0.7)
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.appShadow.opacity(selectedTag?.id == tag.id ? 0 : 0.8), radius: 4, y: 2)
                        .scaleEffect(selectedTag?.id == tag.id ? 1.0 : 0.96)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Tag: \(tag.name)")
                    .accessibilityAddTraits(selectedTag?.id == tag.id ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
