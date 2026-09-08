# ColorPicker

## Color catalog browser

`ColorCatalogBrowserView` lets a user browse four bundled color catalogs — Pantone, IKEA,
RAL, and Sherwin-Williams — and pick a color to add to a palette.

- **Models** (`PaletteModels/`, synchronized into both the `ColorPicker` app target and the
  `ColorPickerWidgets` extension target):
  - `ColorDataProtocol.swift` — the `ColorDataProtocol` protocol (`id`, `name`, `hex`, `rgb`,
    `cmyk`) every catalog color conforms to, plus the catalogs' own `RGB`/`CMYK` value types
    (0–255 / 0–100 integers — distinct from the app's `RGBColor` and `SavedColor.CMYK`, which
    are 0...1 normalized).
  - `PantoneColor.swift`, `IKEAColor.swift`, `RALCatalogColor.swift`, `SherwinWilliamsColor.swift`
    — one `ColorDataProtocol`-conforming struct per catalog, each with a static palette array.
    `RALCatalogColor` is named to avoid colliding with the app-wide `RALColor` in
    `SharedColors/RALColor.swift`, which is a different, unrelated type used throughout saved
    colors and palettes.
  - `ColorPicker/Models/ColorCatalog.swift` — the `ColorCatalog` enum (`.pantone`, `.ikea`,
    `.ral`, `.sherwinWilliams`) identifying the four sources by display name and color count,
    so the UI can switch catalogs without knowing their concrete `ColorDataProtocol` type.
- **ViewModel** (`ColorPicker/ViewModels/ColorCatalogViewModel.swift`): a single generic
  `ColorCatalogViewModel<T: ColorDataProtocol>` shared by all four catalogs instead of one
  view model per catalog. `searchText` is debounced (250ms, via Combine) before it feeds
  `filteredColors`, since each catalog holds 200–1000+ entries.
- **Views** (`ColorPicker/Views/`):
  - `ColorCatalogBrowserView.swift` — the sheet itself: a segmented control across the four
    catalogs, a search field bound to the active catalog's `searchText`, and a `LazyVGrid` of
    swatches.
  - `ColorSwatchView.swift` — the reusable grid cell (swatch + name + hex).
- **Entry point**: a "Обзор каталога цветов" button in `AddPaletteColorsView` presents the
  browser as a sheet. Picking a color calls
  `AddPaletteColorsViewModel.addCatalogColorToPalette(_:)`, which adds it straight to the
  active palette — the method name is explicit about that because `AddPaletteColorsView` is
  reached from the palette-adding flow, not a standalone color editor.

## Tests

`Tests/` holds standalone, precondition-based test executables (no XCTest target) — each
compiled directly against the specific source files it exercises, then run as a plain binary.

- `SharedColorsTests.swift` — `SharedColors/` persistence, migration, and RAL matching.
- `ColorCatalogViewModelTests.swift` — `ColorCatalogViewModel`'s debounced search filtering,
  using a fake `ColorDataProtocol` fixture instead of a real catalog so the logic stays fast
  and independent of catalog data.
