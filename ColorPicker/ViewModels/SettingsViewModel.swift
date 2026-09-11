import SwiftUI

enum SettingsAction: String, Identifiable {
    case premium, privacy, contact, restore, terms

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .premium: "Перейти на Premium"
        case .privacy: "Конфиденциальность"
        case .contact: "Обратная связь"
        case .restore: "Восстановить покупки"
        case .terms: "Условия использования"
        }
    }

    static let rows: [Self] = [.privacy, .contact, .restore, .terms]
}

/// Owns which settings row is currently presenting its (placeholder) alert,
/// plus the real restore-purchases flow (the only row backed by actual
/// StoreKit logic; the rest stay placeholders).
@Observable
final class SettingsViewModel {
    var selectedAction: SettingsAction?
    var restoreResultMessage: String?
    private(set) var isRestoring = false

    private let store: SubscriptionStore

    init(store: SubscriptionStore = .shared) {
        self.store = store
    }

    @MainActor
    func restorePurchases() async {
        guard !isRestoring else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await store.restorePurchases()
            restoreResultMessage = store.isSubscribed
                ? "Покупки восстановлены."
                : "Активные покупки не найдены."
        } catch {
            restoreResultMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
