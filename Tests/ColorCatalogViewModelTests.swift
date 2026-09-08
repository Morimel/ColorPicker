import Foundation

/// Standalone test executable, compiled against `PaletteModels/ColorDataProtocol.swift` and
/// `ColorPicker/ViewModels/ColorCatalogViewModel.swift` only — mirrors `SharedColorsTests`'
/// precondition-based style. Uses a fake catalog fixture instead of the real
/// 200–1000+ entry Pantone/IKEA/RAL/Sherwin-Williams data so the search-filter logic can be
/// checked in isolation and stay fast.
private struct FakeCatalogColor: ColorDataProtocol {
    let id: String
    let name: String
    let hex: String
    let rgb: RGB
    let cmyk: CMYK

    init(id: String, name: String, hex: String) {
        self.id = id
        self.name = name
        self.hex = hex
        self.rgb = RGB(r: 0, g: 0, b: 0)
        self.cmyk = CMYK(c: 0, m: 0, y: 0, k: 0)
    }
}

private let fakeCatalog: [FakeCatalogColor] = [
    FakeCatalogColor(id: "FAKE 001", name: "Signal blue", hex: "#1E3F66"),
    FakeCatalogColor(id: "FAKE 002", name: "Traffic red", hex: "#C40233"),
    FakeCatalogColor(id: "FAKE 003", name: "Leaf green", hex: "#3E8E41"),
]

@main
struct ColorCatalogViewModelTests {
    @MainActor
    static func main() async throws {
        func check(_ condition: @autoclosure () -> Bool, _ message: String = "Check failed") {
            precondition(condition(), message)
        }

        // Empty search returns the whole catalog, unfiltered.
        let viewModel = ColorCatalogViewModel(catalog: fakeCatalog, debounce: .milliseconds(30))
        check(viewModel.filteredColors.map(\.id) == fakeCatalog.map(\.id), "Empty search must return the full catalog")

        // A name match survives the debounce window.
        viewModel.searchText = "blue"
        check(viewModel.filteredColors.count == fakeCatalog.count, "filteredColors must not react before the debounce fires")
        try await Task.sleep(for: .milliseconds(150))
        check(viewModel.filteredColors.map(\.id) == ["FAKE 001"], "Debounced search must filter by name, case-insensitively")

        // An id match also works, and is case-insensitive.
        viewModel.searchText = "fake 002"
        try await Task.sleep(for: .milliseconds(150))
        check(viewModel.filteredColors.map(\.id) == ["FAKE 002"], "Debounced search must also match on id")

        // No match empties the results rather than falling back to the full catalog.
        viewModel.searchText = "nonexistent"
        try await Task.sleep(for: .milliseconds(150))
        check(viewModel.filteredColors.isEmpty, "A non-matching search must return no colors")

        // Clearing the search restores the full catalog.
        viewModel.searchText = ""
        try await Task.sleep(for: .milliseconds(150))
        check(viewModel.filteredColors.count == fakeCatalog.count, "Clearing the search must restore the full catalog")

        // selectedColor is independent of search/filtering.
        viewModel.selectedColor = fakeCatalog[1]
        check(viewModel.selectedColor?.id == "FAKE 002", "selectedColor must hold whatever was last assigned")

        print("PASS: ColorCatalogViewModel debounced search filtering (name, id, no-match, clear) and selection")
    }
}
