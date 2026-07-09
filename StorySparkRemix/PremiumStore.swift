import Foundation
import StoreKit

final class PremiumStore: ObservableObject {
    @Published var isPremiumUnlocked = false
    @Published var unavailableMessage: String?

    private let productID = "storysparkremix.premium.unlimited"

    @MainActor
    func loadProducts() async {
        guard #available(iOS 15.0, *) else {
            unavailableMessage = "Premium needs StoreKit 2 on iOS 15 or later. Core writing stays free."
            return
        }
        do {
            let products = try await Product.products(for: [productID])
            if products.isEmpty {
                unavailableMessage = "Premium is not configured yet. You can still create and save sparks."
            }
        } catch {
            unavailableMessage = "Premium is unavailable right now. Core writing stays free."
        }
    }

    @MainActor
    func restorePurchases() async {
        guard #available(iOS 15.0, *) else {
            unavailableMessage = "Restore purchases needs StoreKit 2 on iOS 15 or later."
            return
        }
        do {
            try await AppStore.sync()
            unavailableMessage = "Restore finished. No active premium receipt was found on this device."
        } catch {
            unavailableMessage = "Restore could not finish. Try again from Settings."
        }
    }
}
