import Foundation

/// The closest entry across all four bundled catalogs (Pantone/IKEA/RAL/Sherwin-Williams)
/// to a given color.
struct NearestCatalogMatch: Equatable {
    let catalog: ColorCatalog
    let name: String
    let code: String
    let hex: String
}

/// Searches the full Pantone/IKEA/RAL classic/Sherwin-Williams catalogs (~2000 colors
/// combined) for the closest match to a sampled/converted color — a much richer
/// comparison than the app's small ~23-color RAL starter palette used for saved colors.
enum NearestCatalogColor {
    static func find(for rgb: RGBColor) -> NearestCatalogMatch? {
        var best: (catalog: ColorCatalog, name: String, code: String, hex: String, distance: Int)?

        func consider<T: ColorDataProtocol>(_ catalog: ColorCatalog, _ entries: [T]) {
            for entry in entries {
                let d = distanceSquared(rgb, entry.rgb)
                if best == nil || d < best!.distance {
                    best = (catalog, entry.name, entry.id, entry.hex, d)
                }
            }
        }

        consider(.pantone, PantoneColor.pantonePalette)
        consider(.ikea, IKEAColor.ikeaPalette)
        consider(.ral, RALCatalogColor.classic)
        consider(.sherwinWilliams, SherwinWilliamsColor.sherwinWilliamsPalette)

        guard let best else { return nil }
        return NearestCatalogMatch(catalog: best.catalog, name: best.name, code: best.code, hex: best.hex)
    }

    private static func distanceSquared(_ rgb: RGBColor, _ entry: RGB) -> Int {
        let dr = rgb.r - entry.r
        let dg = rgb.g - entry.g
        let db = rgb.b - entry.b
        return dr * dr + dg * dg + db * db
    }
}
