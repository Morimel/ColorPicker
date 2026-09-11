//
//  ColorCatalog.swift
//  ColorPicker
//

import Foundation

/// Identifies one of the bundled color catalogs so `ColorCatalogBrowserView` can switch
/// between them without knowing the concrete `ColorDataProtocol` type behind each tab.
enum ColorCatalog: String, CaseIterable, Identifiable {
    case pantone
    case ikea
    case ral
    case sherwinWilliams

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pantone: "Pantone"
        case .ikea: "IKEA"
        case .ral: "RAL"
        case .sherwinWilliams: "Sherwin-Williams"
        }
    }

    var colorCount: Int {
        switch self {
        case .pantone: PantoneColor.pantonePalette.count
        case .ikea: IKEAColor.ikeaPalette.count
        case .ral: RALCatalogColor.classic.count
        case .sherwinWilliams: SherwinWilliamsColor.sherwinWilliamsPalette.count
        }
    }
}

/// Which catalogs `NearestCatalogColor.find(for:in:)` searches on Camera and
/// Photo: either the closest entry across all four bundled catalogs, or
/// restricted to one brand the user picked via the on-screen brand row (see
/// `BrandFilterRow` and each screen's three-dots menu).
enum CatalogMatchMode {
    case allBrands, singleBrand
}
