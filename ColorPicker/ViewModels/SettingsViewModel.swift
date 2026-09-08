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

/// Owns which settings row is currently presenting its (placeholder) alert.
@Observable
final class SettingsViewModel {
    var selectedAction: SettingsAction?
}
