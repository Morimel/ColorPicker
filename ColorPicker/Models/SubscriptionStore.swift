import Foundation
import StoreKit

/// A top-level screen that's free to open once and then paywalled.
enum GatedScreen: String, CaseIterable {
    case camera, photo, converter, palettes, saved

    fileprivate var visitedDefaultsKey: String { "hasVisited_\(rawValue)" }
}

/// Single source of truth for whether the user currently has an active
/// subscription, backed by StoreKit 2. Every gate in the app (`canVisit`,
/// `ColorInfoCard.locksWhenFree`, the post-onboarding paywall) reads
/// `isSubscribed` live rather than a cached snapshot, so once entitlements
/// change here — a purchase, a renewal, an expiration, a refund — every
/// screen reacts automatically without any further wiring.
@Observable
final class SubscriptionStore {
    static let shared = SubscriptionStore()

    private(set) var isSubscribed: Bool = false
    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    var lastErrorMessage: String?

    /// Placeholder App Store Connect product identifiers — swap these for the
    /// real ones once the products exist there. `.lifetime` must be
    /// configured as a non-consumable; `.week`/`.annual` as auto-renewable
    /// subscriptions in the same subscription group so purchasing one
    /// upgrades/replaces the other.
    static let productIDs: [PricingPlan.Kind: String] = [
        .week: "com.IsaMelsov.ColorPicker.pro.week",
        .annual: "com.IsaMelsov.ColorPicker.pro.annual",
        .lifetime: "com.IsaMelsov.ColorPicker.pro.lifetime",
    ]

    enum PurchaseOutcome {
        case success, pending, cancelled
    }

    enum StoreError: LocalizedError {
        case productUnavailable
        case failedVerification

        var errorDescription: String? {
            switch self {
            case .productUnavailable: "Этот план сейчас недоступен."
            case .failedVerification: "Не удалось подтвердить покупку."
            }
        }
    }

    private let defaults: UserDefaults
    private var transactionListener: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        transactionListener = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(transactionResult: update)
            }
        }
        Task { [weak self] in
            await self?.loadProducts()
            await self?.refreshEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    /// Whether `screen` may be opened right now: subscribers always may;
    /// everyone else gets exactly one free visit, tracked permanently (not
    /// just for the session) so relaunching the app doesn't reset it. The
    /// first call for a given screen both answers `true` and consumes that
    /// free visit, so call this once per navigation attempt, not per render.
    func canVisit(_ screen: GatedScreen) -> Bool {
        guard !isSubscribed else { return true }
        guard !defaults.bool(forKey: screen.visitedDefaultsKey) else { return false }
        defaults.set(true, forKey: screen.visitedDefaultsKey)
        return true
    }

    // MARK: Products

    @MainActor
    func loadProducts() async {
        guard products.isEmpty, !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: Array(Self.productIDs.values))
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func product(for plan: PricingPlan.Kind) -> Product? {
        guard let id = Self.productIDs[plan] else { return nil }
        return products.first { $0.id == id }
    }

    // MARK: Purchasing

    @MainActor
    func purchase(_ plan: PricingPlan.Kind) async throws -> PurchaseOutcome {
        guard let product = product(for: plan) else {
            throw StoreError.productUnavailable
        }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            await refreshEntitlements()
            await transaction.finish()
            return .success
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .cancelled
        }
    }

    /// Re-syncs with the App Store (prompting for the Apple ID if needed)
    /// and re-derives `isSubscribed` from the refreshed entitlements.
    @MainActor
    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: Entitlements

    @MainActor
    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.checkVerified(result) else { continue }
            if transaction.revocationDate == nil {
                active = true
            }
        }
        isSubscribed = active
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard let transaction = try? Self.checkVerified(transactionResult) else { return }
        await refreshEntitlements()
        await transaction.finish()
    }

    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}
