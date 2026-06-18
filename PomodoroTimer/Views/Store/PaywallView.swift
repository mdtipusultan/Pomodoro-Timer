import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitService.self) private var store
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private let benefits = [
        "Unlimited stats history",
        "Edit & delete sessions",
        "Double likability",
        "All future animals",
        "Dark mode",
        "All app icons"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    benefitsList
                    productsList
                    restoreButton
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                if store.products.isEmpty {
                    await store.loadProducts()
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            LinearGradient(
                colors: [.appOrange, .orange.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                Text("Go Pro")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
            }
        }
    }

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(benefits, id: \.self) { benefit in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.appOrange)
                    Text(benefit)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var productsList: some View {
        VStack(spacing: 12) {
            if store.isLoading {
                ProgressView()
            } else if store.subscriptionProducts.isEmpty {
                mockProductButtons
            } else {
                ForEach(store.subscriptionProducts, id: \.id) { product in
                    ProductRowView(
                        product: product,
                        isBestValue: product.id.contains("yearly"),
                        onPurchase: { purchase(product) }
                    )
                }
            }
        }
    }

    private var mockProductButtons: some View {
        VStack(spacing: 12) {
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
            HStack {
                Text(title).font(.headline)
                Spacer()
                if best {
                    Text("Best Value")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.appOrange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(best ? Color.appOrange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task {
                do {
                    try await store.restorePurchases()
                    if store.isProUser { dismiss() }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func purchase(_ product: Product) {
        isPurchasing = true
        Task {
            do {
                let success = try await store.purchase(product)
                if success { dismiss() }
            } catch {
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
