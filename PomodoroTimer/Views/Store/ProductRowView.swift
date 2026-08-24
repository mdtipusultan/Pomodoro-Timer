import StoreKit
import SwiftUI

struct ProductRowView: View {
    let product: Product
    let isBestValue: Bool
    var isCurrent: Bool = false
    let onPurchase: () -> Void
    
    @State private var isPressed = false

    var body: some View {
        Button(action: onPurchase) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.subheadline.weight(.semibold))
                        if isCurrent {
                            Text("Current")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appOrange, in: Capsule())
                                .foregroundStyle(.white)
                        } else if isBestValue {
                            Text("Best")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appOrange, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(product.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(isCurrent ? "Active" : product.displayPrice)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(isBestValue || isCurrent ? Color.appOrange : .primary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isBestValue || isCurrent ? Color.appOrange : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.appShadow.opacity(isBestValue || isCurrent ? 0.12 : 0.06), radius: isBestValue || isCurrent ? 8 : 6, x: 0, y: 3)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}
