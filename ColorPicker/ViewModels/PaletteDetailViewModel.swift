import Foundation

/// Owns the sheet/toast state and the palette lookup for `PaletteDetailView`.
/// The palette is looked up live from the store (so colors added elsewhere
/// show up immediately) rather than copied in once.
@Observable
final class PaletteDetailViewModel {
    private let originalPalette: Palette
    private let store: PaletteStore

    var showsAddColors = false
    var showsCopiedToast = false

    init(palette: Palette, store: PaletteStore) {
        self.originalPalette = palette
        self.store = store
    }

    var currentPalette: Palette {
        store.palettes.first { $0.id == originalPalette.id } ?? originalPalette
    }

    var entries: [(rgb: RGBColor, ral: RALColor)] {
        currentPalette.colors.map { ($0.rgb, $0.ral) }
    }

    func markCopied() {
        showsCopiedToast = true
    }

    /// Renders the current palette to a temp PDF file, or `nil` if it has no colors yet.
    func exportPDF() -> URL? {
        let palette = currentPalette
        let entries = palette.colors.map(PDFColorExport.Entry.init)
        return PDFColorExport.makePDF(documentTitle: palette.name, sections: [.init(title: "", entries: entries)])
    }
}
