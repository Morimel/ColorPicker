import Foundation

/// Owns the palette list for `PalettesView`.
@Observable
final class PalettesViewModel {
    private let store: PaletteStore

    init(store: PaletteStore) {
        self.store = store
    }

    var palettes: [Palette] { store.palettes }
}
