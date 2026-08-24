import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitService.self) private var store
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showManageSubscriptions = false

    private let benefits = [
        ("chart.bar.fill", "Unlimited stats history"),
        ("pencil.and.list.clipboard", "Edit & delete sessions"),
        ("heart.fill", "Double likability"),
        ("hare.fill", "All future animals"),
        ("moon.fill", "Dark mode"),
        ("app.gift.fill", "All app icons")
    ]

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        HapticManager.shared.buttonTap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close paywall")
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }
                
                // Content
                VStack(spacing: 20) {
                    Spacer(minLength: 0)
                    
                    header
                    
                    benefitsGrid
                    
                    Spacer(minLength: 10)
                    
                    productsList
                    
                    restoreButton
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appOrange.opacity(0.14))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                Circle()
                    .fill(Color.appOrange.opacity(0.14))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "cat.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.appOrange)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 6) {
                Text(store.isProUser ? "ChickFocus Pro" : "Unlock ChickFocus Pro")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(store.isProUser
                     ? "You're a Pro member. Change plans anytime."
                     : "More companions, full history, and dark mode")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var benefitsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(benefits, id: \.1) { icon, benefit in
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(Color.appOrange)
                        .frame(width: 36, height: 36)
                        .background(Color.appOrange.opacity(0.14), in: Circle())
                    
                    Text(benefit)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var productsList: some View {
        VStack(spacing: 10) {
            if store.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.appOrange)
                    Text("Loading products...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if store.subscriptionProducts.isEmpty {
                mockProductButtons
            } else {
                ForEach(store.subscriptionProducts, id: \.id) { product in
                    ProductRowView(
                        product: product,
                        isBestValue: product.id.contains("yearly"),
                        isCurrent: store.purchasedProductIDs.contains(product.id),
                        onPurchase: { purchase(product) }
                    )
                }
            }
        }
    }

    private var mockProductButtons: some View {
        VStack(spacing: 10) {
            mockButton("Monthly — $3.99/mo", best: false)
            mockButton("Yearly — $9.99/yr", best: true)
            mockButton("Lifetime — $24.99", best: false)
        }
    }

    private func mockButton(_ title: String, best: Bool) -> some View {
        Button {
            #if DEBUG
            store.enableMockPro()
            dismiss()
            #endif
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title.components(separatedBy: " — ").first ?? title)
                            .font(.subheadline.weight(.semibold))
                        if best {
                            Text("Best")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appOrange, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    if let price = title.components(separatedBy: " — ").last {
                        Text(price)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(title.components(separatedBy: " — ").last ?? "")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(best ? Color.appOrange : .primary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(best ? Color.appOrange : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.appShadow.opacity(best ? 0.12 : 0.06), radius: best ? 8 : 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var restoreButton: some View {
        VStack(spacing: 8) {
            if store.isProUser {
                Button("Manage in App Store") {
                    HapticManager.shared.buttonTap()
                    showManageSubscriptions = true
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }

            Button("Restore Purchases") {
                HapticManager.shared.buttonTap()
                Task {
                    do {
                        let wasPro = store.isProUser
                        try await store.restorePurchases()
                        if store.isProUser {
                            HapticManager.shared.sessionComplete()
                            if !wasPro { dismiss() }
                        }
                    } catch {
                        HapticManager.shared.sessionFailed()
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Link("Privacy", destination: URL(string: "https://example.com/privacy")!)
                Text("•")
                    .foregroundStyle(.quaternary)
                Link("Terms", destination: URL(string: "https://example.com/terms")!)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }

    private func purchase(_ product: Product) {
        HapticManager.shared.buttonTap()
        if store.purchasedProductIDs.contains(product.id) {
            showManageSubscriptions = true
            return
        }
        isPurchasing = true
        Task {
            do {
                let success = try await store.purchase(product)
                if success { 
                    HapticManager.shared.sessionComplete()
                    dismiss() 
                } else {
                    HapticManager.shared.buttonTap()
                }
            } catch {
                HapticManager.shared.sessionFailed()
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }
}

#Preview {
    PaywallView()
        .environment(StoreKitService())
}
