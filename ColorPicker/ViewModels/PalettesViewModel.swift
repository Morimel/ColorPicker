import Foundation

/// Owns the palette list for `PalettesView`.
@Observable
final class PalettesViewModel {
    private let store: PaletteStore

    init(store: PaletteStore) {
        self.store = store
    }

    var palettes: [Palette] { store.palettes }

    /// Starts a new, empty palette so the user has somewhere to add colors to —
    /// including via the catalog browser, which only ever adds to an existing palette.
    @discardableResult
    func createPalette() -> Palette {
        store.add(colors: [])
    }

    func delete(at offsets: IndexSet) {
        store.remove(at: offsets)
    }
}
