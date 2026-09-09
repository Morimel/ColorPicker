import Foundation

/// Owns the palette list, multi-select, and delete/share/export actions for `PalettesView`.
@Observable
final class PalettesViewModel {
    private let store: PaletteStore

    var isSelecting = false
    var selectedPaletteIDs: Set<UUID> = []

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

    // MARK: Multi-select

    func toggleSelection(_ id: UUID) {
        if selectedPaletteIDs.contains(id) {
            selectedPaletteIDs.remove(id)
        } else {
            selectedPaletteIDs.insert(id)
        }
    }

    func toggleSelectAll() {
        selectedPaletteIDs = isAllSelected ? [] : Set(palettes.map(\.id))
    }

    var isAllSelected: Bool {
        !palettes.isEmpty && selectedPaletteIDs.count == palettes.count
    }

    func hasSelection() -> Bool {
        !selectedPaletteIDs.isEmpty
    }

    var selectionShareText: String {
        palettes.filter { selectedPaletteIDs.contains($0.id) }
            .map(\.shareText).joined(separator: "\n\n")
    }

    /// Renders the selected palettes to a temp PDF file, or `nil` if nothing is selected.
    /// Each palette becomes its own titled section.
    func exportSelectionPDF() -> URL? {
        let sections = palettes
            .filter { selectedPaletteIDs.contains($0.id) }
            .map { PDFColorExport.Section(title: $0.name, entries: $0.colors.map(PDFColorExport.Entry.init)) }
        return PDFColorExport.makePDF(documentTitle: "Палитры", sections: sections)
    }

    func deleteSelected() {
        for palette in palettes where selectedPaletteIDs.contains(palette.id) {
            store.remove(palette)
        }
        exitSelectionMode()
    }

    func exitSelectionMode() {
        isSelecting = false
        selectedPaletteIDs.removeAll()
    }
}
