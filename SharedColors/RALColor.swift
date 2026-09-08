//
//  RALColor.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import Foundation

// MARK: - RGBColor

struct RGBColor: Codable, Equatable, Hashable {
    var r: Int
    var g: Int
    var b: Int

    var hexString: String {
        String(format: "#%02X%02X%02X", r, g, b)
    }

    /// Simple, non-color-managed RGB -> CMYK conversion.
    var cmyk: (c: Int, m: Int, y: Int, k: Int) {
        if r == 0 && g == 0 && b == 0 {
            return (0, 0, 0, 100)
        }

        let rf = Double(r) / 255
        let gf = Double(g) / 255
        let bf = Double(b) / 255

        let k = 1 - max(rf, gf, bf)
        let c = (1 - rf - k) / (1 - k)
        let m = (1 - gf - k) / (1 - k)
        let y = (1 - bf - k) / (1 - k)

        return (
            Int((c * 100).rounded()),
            Int((m * 100).rounded()),
            Int((y * 100).rounded()),
            Int((k * 100).rounded())
        )
    }

    var cmykString: String {
        let values = cmyk
        return "\(values.c) \(values.m) \(values.y) \(values.k)"
    }

    var rgbString: String {
        "\(r) \(g) \(b)"
    }
}

// MARK: - RGBColor conversions

extension RGBColor {
    /// Parses a "#RRGGBB" or "RRGGBB" hex string. Returns `nil` for anything
    /// that isn't exactly 6 valid hex digits.
    init?(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") { sanitized.removeFirst() }

        guard sanitized.count == 6, let value = UInt32(sanitized, radix: 16) else { return nil }

        self.init(
            r: Int((value & 0xFF0000) >> 16),
            g: Int((value & 0x00FF00) >> 8),
            b: Int(value & 0x0000FF)
        )
    }

    /// Simple, non-color-managed CMYK -> RGB conversion (inverse of `cmyk`).
    init(c: Int, m: Int, y: Int, k: Int) {
        let cf = Double(RGBColor.clampPercent(c)) / 100
        let mf = Double(RGBColor.clampPercent(m)) / 100
        let yf = Double(RGBColor.clampPercent(y)) / 100
        let kf = Double(RGBColor.clampPercent(k)) / 100

        self.init(
            r: Int((255 * (1 - cf) * (1 - kf)).rounded()),
            g: Int((255 * (1 - mf) * (1 - kf)).rounded()),
            b: Int((255 * (1 - yf) * (1 - kf)).rounded())
        )
    }

    static func clampChannel(_ value: Int) -> Int {
        min(max(value, 0), 255)
    }

    static func clampPercent(_ value: Int) -> Int {
        min(max(value, 0), 100)
    }
}

// MARK: - RALColor

struct RALColor: Identifiable, Codable, Equatable, Hashable {
    var code: String
    var nameRu: String
    var nameEn: String
    var hex: String
    var r: Int
    var g: Int
    var b: Int

    var id: String { code }

    var rgb: RGBColor { RGBColor(r: r, g: g, b: b) }

    /// Picks the RAL name matching the app's resolved language, falling back
    /// to Russian (the app's source language) for anything else.
    var localizedName: String {
        Bundle.main.preferredLocalizations.first == "en" ? nameEn : nameRu
    }

    init(code: String, nameRu: String, nameEn: String, hex: String, r: Int, g: Int, b: Int) {
        self.code = code
        self.nameRu = nameRu
        self.nameEn = nameEn
        self.hex = hex
        self.r = r
        self.g = g
        self.b = b
    }

    private enum CodingKeys: String, CodingKey {
        case code, nameRu, nameEn, hex, r, g, b
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        code = try values.decode(String.self, forKey: .code)
        nameRu = try values.decode(String.self, forKey: .nameRu)
        hex = try values.decode(String.self, forKey: .hex)
        r = try values.decode(Int.self, forKey: .r)
        g = try values.decode(Int.self, forKey: .g)
        b = try values.decode(Int.self, forKey: .b)
        // Colors saved before English names existed have no `nameEn` key.
        nameEn = try values.decodeIfPresent(String.self, forKey: .nameEn) ?? nameRu
    }
}

// MARK: - RAL Classic starter palette

enum RALPalette {
    // TODO: Expand to the full ~213 RAL Classic palette and match in Lab color
    // space (CIE76/CIEDE2000) for perceptually accurate results instead of
    // naive Euclidean RGB distance.
    static let colors: [RALColor] = [
        RALColor(code: "RAL 1000", nameRu: "Зелёно-бежевый", nameEn: "Green beige", hex: "#CCC58F", r: 204, g: 197, b: 143),
        RALColor(code: "RAL 1003", nameRu: "Сигнальный жёлтый", nameEn: "Signal yellow", hex: "#E5BE01", r: 229, g: 190, b: 1),
        RALColor(code: "RAL 1004", nameRu: "Золотисто-жёлтый", nameEn: "Golden yellow", hex: "#CDA434", r: 205, g: 164, b: 52),
        RALColor(code: "RAL 2008", nameRu: "Ярко-красный оранжевый", nameEn: "Bright red orange", hex: "#EC7C26", r: 236, g: 124, b: 38),
        RALColor(code: "RAL 3000", nameRu: "Огненно-красный", nameEn: "Flame red", hex: "#AF2B1E", r: 175, g: 43, b: 30),
        RALColor(code: "RAL 3020", nameRu: "Транспортный красный", nameEn: "Traffic red", hex: "#C1121C", r: 193, g: 18, b: 28),
        RALColor(code: "RAL 4001", nameRu: "Красно-лиловый", nameEn: "Red lilac", hex: "#6D3F5B", r: 109, g: 63, b: 91),
        RALColor(code: "RAL 5015", nameRu: "Небесно-синий", nameEn: "Sky blue", hex: "#2271B3", r: 34, g: 113, b: 179),
        RALColor(code: "RAL 5017", nameRu: "Транспортный синий", nameEn: "Traffic blue", hex: "#063971", r: 6, g: 57, b: 113),
        RALColor(code: "RAL 6002", nameRu: "Лиственно-зелёный", nameEn: "Leaf green", hex: "#317F43", r: 49, g: 127, b: 67),
        RALColor(code: "RAL 6005", nameRu: "Зелёный мох", nameEn: "Moss green", hex: "#0F4336", r: 15, g: 67, b: 54),
        RALColor(code: "RAL 6018", nameRu: "Жёлто-зелёный", nameEn: "Yellow green", hex: "#57A639", r: 87, g: 166, b: 57),
        RALColor(code: "RAL 6019", nameRu: "Бело-зелёный", nameEn: "Pastel green", hex: "#B7D9B1", r: 183, g: 217, b: 177),
        RALColor(code: "RAL 7016", nameRu: "Антрацитово-серый", nameEn: "Anthracite grey", hex: "#293133", r: 41, g: 49, b: 51),
        RALColor(code: "RAL 7035", nameRu: "Светло-серый", nameEn: "Light grey", hex: "#D7D7D7", r: 215, g: 215, b: 215),
        RALColor(code: "RAL 7047", nameRu: "Телегрей 4", nameEn: "Telegrey 4", hex: "#D0D0D0", r: 208, g: 208, b: 208),
        RALColor(code: "RAL 8003", nameRu: "Глиняно-коричневый", nameEn: "Clay brown", hex: "#7E3921", r: 126, g: 57, b: 33),
        RALColor(code: "RAL 8017", nameRu: "Шоколадно-коричневый", nameEn: "Chocolate brown", hex: "#45322E", r: 69, g: 50, b: 46),
        RALColor(code: "RAL 9001", nameRu: "Кремово-белый", nameEn: "Cream", hex: "#FDF4E3", r: 253, g: 244, b: 227),
        RALColor(code: "RAL 9003", nameRu: "Сигнальный белый", nameEn: "Signal white", hex: "#F4F4F4", r: 244, g: 244, b: 244),
        RALColor(code: "RAL 9005", nameRu: "Чёрный янтарь", nameEn: "Jet black", hex: "#0A0A0A", r: 10, g: 10, b: 10),
        RALColor(code: "RAL 9010", nameRu: "Белый", nameEn: "Pure white", hex: "#FFFFFF", r: 255, g: 255, b: 255),
        RALColor(code: "RAL 9016", nameRu: "Транспортный белый", nameEn: "Traffic white", hex: "#F6F6F6", r: 246, g: 246, b: 246),
    ]

    /// Nearest RAL Classic color by Euclidean distance in RGB space.
    ///
    /// TODO: replace with Lab-space distance (CIEDE2000) once the full RAL
    /// Classic set is seeded — RGB Euclidean distance doesn't track human
    /// perceived color difference well, especially near hue boundaries.
    static func nearestRALColor(to color: RGBColor) -> RALColor {
        colors.min { lhs, rhs in
            distanceSquared(color, lhs.rgb) < distanceSquared(color, rhs.rgb)
        } ?? colors[0]
    }

    private static func distanceSquared(_ a: RGBColor, _ b: RGBColor) -> Int {
        let dr = a.r - b.r
        let dg = a.g - b.g
        let db = a.b - b.b
        return dr * dr + dg * dg + db * db
    }

    /// A label for a color that's either a real RAL match or, when the
    /// nearest swatch is too far off to be meaningful, a generated
    /// "Custom_XXXXXXXX" placeholder instead of a misleading RAL name.
    struct DisplayMatch {
        let code: String
        let name: String
        let isRALMatch: Bool
    }

    /// Below this squared-distance, the nearest RAL swatch is treated as a
    /// legitimate match. Above it (e.g. a pixel picked from a photo that
    /// doesn't resemble anything in this ~23-color starter palette), calling
    /// it a RAL color would be misleading, so we fall back to a generated
    /// "Custom_" label instead. Threshold picked empirically (~60 units of
    /// per-channel slack); revisit once the full RAL Classic set is seeded.
    private static let looseMatchThresholdSquared = 60 * 60 * 3

    static func displayMatch(for color: RGBColor) -> DisplayMatch {
        let nearest = nearestRALColor(to: color)
        guard distanceSquared(color, nearest.rgb) <= looseMatchThresholdSquared else {
            let name = Bundle.main.preferredLocalizations.first == "en" ? "Matched color" : "Подобранный цвет"
            return DisplayMatch(code: "Custom_\(customSuffix(for: color))", name: name, isRALMatch: false)
        }
        return DisplayMatch(code: nearest.code, name: nearest.localizedName, isRALMatch: true)
    }

    private static func customSuffix(for color: RGBColor) -> String {
        var hasher = Hasher()
        hasher.combine(color.r)
        hasher.combine(color.g)
        hasher.combine(color.b)
        let value = UInt32(truncatingIfNeeded: hasher.finalize())
        return String(format: "%08X", value)
    }
}
