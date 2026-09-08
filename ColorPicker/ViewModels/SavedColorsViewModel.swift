import Foundation

/// Owns the tab/selection/navigation state for `SavedColorsView`, and is the
/// only thing that view talks to — it holds both stores itself and exposes
/// the color/palette data and mutations the view needs, so the view never
/// references `SavedColorsStore`/`PaletteStore` directly.
@Observable
final class SavedColorsViewModel {

    enum Tab: Hashable {
        case colors, palettes
    }

    private let savedColorsStore: SavedColorsStore
    private let paletteStore: PaletteStore

    var selectedTab: Tab = .colors
    var paletteToBrowse: Palette?
    var showsCopiedToast = false

    var colorToBrowse: UUID?
    var isSelecting = false
    var selectedColorIDs: Set<UUID> = []
    var selectedPaletteIDs: Set<UUID> = []

    init(savedColorsStore: SavedColorsStore, paletteStore: PaletteStore) {
        self.savedColorsStore = savedColorsStore
        self.paletteStore = paletteStore
    }

    // MARK: Model data

    var colors: [SavedColor] { savedColorsStore.savedColors }
    var palettes: [Palette] { paletteStore.palettes }

    func markCopied() {
        showsCopiedToast = true
    }

    func removeColors(at offsets: IndexSet) {
        savedColorsStore.remove(at: offsets)
    }

    func removePalettes(at offsets: IndexSet) {
        paletteStore.remove(at: offsets)
    }

    // MARK: Selection summaries

    func hasSelection() -> Bool {
        switch selectedTab {
        case .colors: !selectedColorIDs.isEmpty
        case .palettes: !selectedPaletteIDs.isEmpty
        }
    }

    var selectionShareText: String {
        switch selectedTab {
        case .colors:
            colors.filter { selectedColorIDs.contains($0.id) }
                .map(\.shareText).joined(separator: "\n\n")
        case .palettes:
            palettes.filter { selectedPaletteIDs.contains($0.id) }
                .map(\.shareText).joined(separator: "\n\n")
        }
    }

    var isAllSelected: Bool {
        switch selectedTab {
        case .colors:
            !colors.isEmpty && selectedColorIDs.count == colors.count
        case .palettes:
            !palettes.isEmpty && selectedPaletteIDs.count == palettes.count
        }
    }

    // MARK: Multi-select

    func toggleColorSelection(_ id: UUID) {
        if selectedColorIDs.contains(id) {
            selectedColorIDs.remove(id)
        } else {
            selectedColorIDs.insert(id)
        }
    }

    func togglePaletteSelection(_ id: UUID) {
        if selectedPaletteIDs.contains(id) {
            selectedPaletteIDs.remove(id)
        } else {
            selectedPaletteIDs.insert(id)
        }
    }

    func toggleSelectAll() {
        switch selectedTab {
        case .colors:
            selectedColorIDs = isAllSelected ? [] : Set(colors.map(\.id))
        case .palettes:
            selectedPaletteIDs = isAllSelected ? [] : Set(palettes.map(\.id))
        }
    }

    func deleteSelected() {
        switch selectedTab {
        case .colors:
            for entry in colors where selectedColorIDs.contains(entry.id) {
                savedColorsStore.remove(entry)
            }
        case .palettes:
            for palette in palettes where selectedPaletteIDs.contains(palette.id) {
                paletteStore.remove(palette)
            }
        }
        exitSelectionMode()
    }

    func exitSelectionMode() {
        isSelecting = false
        selectedColorIDs.removeAll()
        selectedPaletteIDs.removeAll()
    }

    // MARK: PDF export

    /// Renders the current selection to a temp PDF file, or `nil` if nothing is selected.
    /// Colors become a single flat sheet; palettes become one titled section each.
    func exportSelectionPDF() -> URL? {
        switch selectedTab {
        case .colors:
            let entries = colors.filter { selectedColorIDs.contains($0.id) }.map(PDFColorExport.Entry.init)
            return PDFColorExport.makePDF(documentTitle: "Сохранённые цвета", sections: [.init(title: "", entries: entries)])
        case .palettes:
            let sections = palettes
                .filter { selectedPaletteIDs.contains($0.id) }
                .map { PDFColorExport.Section(title: $0.name, entries: $0.colors.map(PDFColorExport.Entry.init)) }
            return PDFColorExport.makePDF(documentTitle: "Палитры", sections: sections)
        }
    }
}
