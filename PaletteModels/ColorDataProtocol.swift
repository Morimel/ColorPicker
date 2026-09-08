//
//  ColorDataProtocol.swift
//  ColorPicker
//

import Foundation

/// A single color entry from an external catalog (Pantone, IKEA, RAL, Sherwin-Williams, ...).
/// `RGB`/`CMYK` are the catalogs' own 0–255 / 0–100 integer representations, distinct from the
/// app's `RGBColor` and `SavedColor.CMYK` (0...1 normalized) used for saved/photo-picked colors.
protocol ColorDataProtocol: Identifiable where ID == String {
    nonisolated var id: String { get }
    nonisolated var name: String { get }
    nonisolated var hex: String { get }
    nonisolated var rgb: RGB { get }
    nonisolated var cmyk: CMYK { get }
}

struct RGB: Equatable, Hashable, Sendable {
    let r: Int
    let g: Int
    let b: Int
}

struct CMYK: Equatable, Hashable, Sendable {
    let c: Int
    let m: Int
    let y: Int
    let k: Int
}
