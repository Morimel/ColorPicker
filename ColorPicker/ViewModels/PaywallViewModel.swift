import SwiftUI
import StoreKit

// MARK: - PricingPlan

struct PricingPlan: Identifiable {
    enum Kind { case week, annual, lifetime }

    let kind: Kind
    let title: LocalizedStringKey
    let price: String
    let badge: LocalizedStringKey
    let detail: LocalizedStringKey
    let billingPeriod: LocalizedStringKey

    var id: Kind { kind }
}

extension PricingPlan.Kind: Identifiable {
    var id: Self { self }
}

// MARK: - PaywallFeature

struct PaywallFeature: Identifiable {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var id: String { icon }
}

// MARK: - PaywallViewModel

/// Owns plan selection and the purchase/restore flow for `PaywallView`,
/// backed by `SubscriptionStore`'s StoreKit 2 integration. Plan prices are
/// read live from the fetched `Product`s (localized to the user's
/// storefront) and only fall back to the placeholder strings below while
/// products haven't loaded yet — e.g. no network, or the product IDs in
/// `SubscriptionStore.productIDs` don't exist in App Store Connect yet.
@Observable
final class PaywallViewModel {

    var selectedPlan: PricingPlan.Kind = .annual
    var showsUnavailableAlert = false
    var errorMessage: String?
    private(set) var isPurchasing = false

    private let store: SubscriptionStore

    init(store: SubscriptionStore = .shared) {
        self.store = store
    }

    // Fallback display conversions use 0.04777 MYR/RUB (Wise, 2026-09-10),
    // used only until the real products load.
    private struct PlanMeta {
        let kind: PricingPlan.Kind
        let title: LocalizedStringKey
        let fallbackPrice: String
        let badge: LocalizedStringKey
        let detail: LocalizedStringKey
        let billingPeriod: LocalizedStringKey
    }

    private let planMeta: [PlanMeta] = [
        PlanMeta(kind: .lifetime, title: "Пожизненно", fallbackPrice: "RM238.37", badge: "НАВСЕГДА", detail: "Один платёж", billingPeriod: "навсегда"),
        PlanMeta(kind: .annual, title: "Год", fallbackPrice: "RM171.97", badge: "ЛУЧШЕЕ", detail: "Оплата раз в год", billingPeriod: "в год"),
        PlanMeta(kind: .week, title: "Неделя", fallbackPrice: "RM40.56", badge: "ГИБКО", detail: "Оплата раз в неделю", billingPeriod: "в неделю"),
    ]

    var plans: [PricingPlan] {
        planMeta.map { meta in
            PricingPlan(
                kind: meta.kind,
                title: meta.title,
                price: store.product(for: meta.kind)?.displayPrice ?? meta.fallbackPrice,
                badge: meta.badge,
                detail: meta.detail,
                billingPeriod: meta.billingPeriod
            )
        }
    }

    let features: [PaywallFeature] = [
        PaywallFeature(icon: "house.fill", title: "Предпросмотр на стене", subtitle: "Посмотрите, как цвет будет смотреться на стене"),
        PaywallFeature(icon: "dollarsign.circle.fill", title: "Экономьте деньги", subtitle: "Избегайте дорогостоящих ошибок с краской"),
        PaywallFeature(icon: "nosign", title: "Без рекламы", subtitle: "Подбирайте цвета без отвлекающей рекламы"),
    ]

    /// Purchases `selectedPlan`. Returns whether the paywall should now be
    /// dismissed (a completed purchase); sets `errorMessage` for anything
    /// that needs surfacing (a failure, or a pending purchase awaiting
    /// approval e.g. Ask to Buy). A user cancellation is silent.
    @MainActor
    func unlockTapped() async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await store.purchase(selectedPlan) {
            case .success:
                return true
            case .pending:
                errorMessage = "Покупка ожидает подтверждения."
                return false
            case .cancelled:
                return false
            }
        } catch {
            errorMessage = message(for: error)
            return false
        }
    }

    /// Re-syncs with the App Store and returns whether that restored an
    /// active entitlement (in which case the paywall should dismiss).
    @MainActor
    func restoreTapped() async -> Bool {
        do {
            try await store.restorePurchases()
            if store.isSubscribed {
                return true
            }
            errorMessage = "Активные покупки не найдены."
            return false
        } catch {
            errorMessage = message(for: error)
            return false
        }
    }

    private func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
