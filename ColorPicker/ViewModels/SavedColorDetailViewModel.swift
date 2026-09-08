import Foundation

/// Owns the color lookup and toast/favorite interactions for
/// `SavedColorDetailView`. The color is looked up live from the store on
/// every access (so edits/deletes made elsewhere are reflected immediately)
/// rather than copied in once.
@Observable
final class SavedColorDetailViewModel {
    private let colorID: UUID
    private let store: SavedColorsStore

    var showsCopiedToast = false

    init(colorID: UUID, store: SavedColorsStore) {
        self.colorID = colorID
        self.store = store
    }

    var color: SavedColor? {
        store.savedColors.first(where: { $0.id == colorID })
    }

    func toggleFavorite() {
        store.toggleFavorite(id: colorID)
    }

    func markCopied() {
        showsCopiedToast = true
    }
}
