import Combine
import Foundation
import StoreKit

final class PremiumStore: ObservableObject {
    @Published private(set) var isPremiumUnlocked: Bool
    @Published var unavailableMessage: String?

    private let productID = "storysparkremix.premium.unlimited"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.isPremiumUnlocked = userDefaults.bool(forKey: SparkPersistenceKeys.premiumUnlocked)
    }

    @MainActor
    func loadProducts() async {
        guard #available(iOS 15.0, *) else {
            unavailableMessage = "Premium needs StoreKit 2 on iOS 15 or later. Core writing stays free."
            return
        }
        do {
            let products = try await Product.products(for: [productID])
            unavailableMessage = products.isEmpty
                ? "Premium is not configured yet. You can still create and save sparks."
                : "Premium is ready. Purchases use StoreKit 2 and stay inside the App Store."
        } catch {
            unavailableMessage = "Premium is unavailable right now. Core writing stays free."
        }
    }

    @MainActor
    func purchasePremium() async {
        guard #available(iOS 15.0, *) else {
            unavailableMessage = "Premium needs StoreKit 2 on iOS 15 or later."
            return
        }
        do {
            guard let product = try await Product.products(for: [productID]).first else {
                unavailableMessage = "Premium is not configured yet. Core writing stays free."
                return
            }
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    unavailableMessage = "Purchase could not be verified. No charge was unlocked here."
                    return
                }
                setPremiumUnlocked(true, message: "Premium unlocked on this device.")
                await transaction.finish()
            case .pending:
                unavailableMessage = "Purchase is pending App Store approval."
            case .userCancelled:
                unavailableMessage = "Purchase cancelled. Core writing stays free."
            @unknown default:
                unavailableMessage = "The App Store returned an unknown purchase state."
            }
        } catch {
            unavailableMessage = "Purchase could not finish. Try again from Settings."
        }
    }

    @MainActor
    func restorePurchases() async {
        guard #available(iOS 15.0, *) else {
            unavailableMessage = "Restore purchases needs StoreKit 2 on iOS 15 or later."
            return
        }
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, transaction.productID == productID else { continue }
            setPremiumUnlocked(true, message: "Premium restored on this device.")
            return
        }
        unavailableMessage = "Restore finished. No active premium receipt was found on this device."
    }

    private func setPremiumUnlocked(_ unlocked: Bool, message: String) {
        isPremiumUnlocked = unlocked
        userDefaults.set(unlocked, forKey: SparkPersistenceKeys.premiumUnlocked)
        unavailableMessage = message
    }

    #if DEBUG
    @MainActor
    func markUnlockedForTesting() {
        setPremiumUnlocked(true, message: "Test premium entitlement saved.")
    }
    #endif
}
