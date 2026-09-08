import Foundation

/// Owns the hex-entry, multi-select, and confirm logic for
/// `AddPaletteColorsView`. Holds both stores itself so the view never
/// references `SavedColorsStore`/`PaletteStore` directly.
@Observable
final class AddPaletteColorsViewModel {
    private let paletteID: UUID
    private let paletteStore: PaletteStore
    private let savedColorsStore: SavedColorsStore

    var selectedIDs: Set<UUID> = []
    var hexText = ""

    init(paletteID: UUID, paletteStore: PaletteStore, savedColorsStore: SavedColorsStore) {
        self.paletteID = paletteID
        self.paletteStore = paletteStore
        self.savedColorsStore = savedColorsStore
    }

    var savedColors: [SavedColor] { savedColorsStore.savedColors }

    var customRGB: RGBColor? {
        RGBColor(hex: hexText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var hasHexInput: Bool {
        !hexText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var colorsToAdd: [SavedColor] {
        var colors = savedColors.filter { selectedIDs.contains($0.id) }
        if let rgb = customRGB {
            colors.append(SavedColor(rgb: rgb, ral: RALPalette.nearestRALColor(to: rgb),
                                     note: "", createdAt: Date()))
        }
        return colors
    }

    func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func confirm() {
        paletteStore.add(colors: colorsToAdd, to: paletteID)
    }
}
