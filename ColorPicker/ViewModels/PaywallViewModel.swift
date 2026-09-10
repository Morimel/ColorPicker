import SwiftUI

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

/// Owns the (currently presentational-only) plan selection for
/// `PaywallView`. There's no App Store product wired up yet, so
/// `unlockTapped()` surfaces the same "not available yet" placeholder
/// `SettingsView`'s other unimplemented rows already use.
@Observable
final class PaywallViewModel {

    var selectedPlan: PricingPlan.Kind = .annual
    var showsUnavailableAlert = false

    // Display conversions use 0.04777 MYR/RUB (Wise, 2026-09-10).
    let plans: [PricingPlan] = [
        PricingPlan(kind: .lifetime, title: "Пожизненно", price: "RM238.37", badge: "НАВСЕГДА", detail: "Один платёж", billingPeriod: "навсегда"),
        PricingPlan(kind: .annual, title: "Год", price: "RM171.97", badge: "ЛУЧШЕЕ", detail: "Оплата раз в год", billingPeriod: "в год"),
        PricingPlan(kind: .week, title: "Неделя", price: "RM40.56", badge: "ГИБКО", detail: "Оплата раз в неделю", billingPeriod: "в неделю"),
    ]

    let features: [PaywallFeature] = [
        PaywallFeature(icon: "house.fill", title: "Предпросмотр на стене", subtitle: "Посмотрите, как цвет будет смотреться на стене"),
        PaywallFeature(icon: "dollarsign.circle.fill", title: "Экономьте деньги", subtitle: "Избегайте дорогостоящих ошибок с краской"),
        PaywallFeature(icon: "nosign", title: "Без рекламы", subtitle: "Подбирайте цвета без отвлекающей рекламы"),
    ]

    func unlockTapped() {
        showsUnavailableAlert = true
    }
}
