import Foundation

/// RGBA and CMYK channels use the normalized 0...1 range.
struct SavedColor: Identifiable, Codable, Equatable {
    struct RGBA: Codable, Equatable {
        var r: Double
        var g: Double
        var b: Double
        var a: Double
    }

    struct CMYK: Codable, Equatable {
        var c: Double
        var m: Double
        var y: Double
        var k: Double
    }

    var id: UUID
    var hex: String
    var rgba: RGBA
    var cmyk: CMYK
    var dateSaved: Date
    var isFavorite: Bool
    var ral: RALColor
    var note: String

    // Compatibility with existing camera, photo, and palette code.
    var rgb: RGBColor {
        RGBColor(r: Int((rgba.r * 255).rounded()),
                 g: Int((rgba.g * 255).rounded()),
                 b: Int((rgba.b * 255).rounded()))
    }
    var createdAt: Date { dateSaved }

    init(id: UUID = UUID(), hex: String, rgba: RGBA, cmyk: CMYK,
         dateSaved: Date = Date(), isFavorite: Bool = false,
         ral: RALColor? = nil, note: String = "") {
        self.id = id
        self.hex = hex
        self.rgba = rgba
        self.cmyk = cmyk
        self.dateSaved = dateSaved
        self.isFavorite = isFavorite
        self.ral = ral ?? RALPalette.nearestRALColor(to: RGBColor(
            r: Int((rgba.r * 255).rounded()), g: Int((rgba.g * 255).rounded()), b: Int((rgba.b * 255).rounded())))
        self.note = note
    }

    init(id: UUID = UUID(), rgb: RGBColor, ral: RALColor, note: String, createdAt: Date,
         isFavorite: Bool = false) {
        let r = Double(rgb.r) / 255, g = Double(rgb.g) / 255, b = Double(rgb.b) / 255
        let k = 1 - max(r, g, b)
        self.init(id: id, hex: rgb.hexString, rgba: RGBA(r: r, g: g, b: b, a: 1),
                  cmyk: CMYK(c: k == 1 ? 0 : (1-r-k)/(1-k),
                             m: k == 1 ? 0 : (1-g-k)/(1-k),
                             y: k == 1 ? 0 : (1-b-k)/(1-k), k: k),
                  dateSaved: createdAt, isFavorite: isFavorite, ral: ral, note: note)
    }

    private enum CodingKeys: String, CodingKey {
        case id, hex, rgba, cmyk, dateSaved, isFavorite, ral, note
        case rgb, createdAt // Legacy app and palette files.
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let id = try values.decode(UUID.self, forKey: .id)
        let note = try values.decodeIfPresent(String.self, forKey: .note) ?? ""
        let favorite = try values.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        if values.contains(.rgba) {
            let hex = try values.decode(String.self, forKey: .hex)
            let rgba = try values.decode(RGBA.self, forKey: .rgba)
            let cmyk = try values.decode(CMYK.self, forKey: .cmyk)
            guard RGBColor(hex: hex) != nil,
                  [rgba.r, rgba.g, rgba.b, rgba.a, cmyk.c, cmyk.m, cmyk.y, cmyk.k]
                    .allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
                throw DecodingError.dataCorruptedError(forKey: .rgba, in: values, debugDescription: "Invalid color channels")
            }
            self.init(id: id, hex: hex,
                      rgba: rgba,
                      cmyk: cmyk,
                      dateSaved: try values.decode(Date.self, forKey: .dateSaved),
                      isFavorite: favorite, ral: try values.decodeIfPresent(RALColor.self, forKey: .ral), note: note)
        } else {
            let rgb = try values.decode(RGBColor.self, forKey: .rgb)
            guard [rgb.r, rgb.g, rgb.b].allSatisfy({ (0...255).contains($0) }) else {
                throw DecodingError.dataCorruptedError(forKey: .rgb, in: values, debugDescription: "Invalid legacy RGB channels")
            }
            self.init(id: id, rgb: rgb,
                      ral: try values.decodeIfPresent(RALColor.self, forKey: .ral) ?? RALPalette.nearestRALColor(to: rgb),
                      note: note, createdAt: try values.decode(Date.self, forKey: .createdAt), isFavorite: favorite)
        }
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(hex, forKey: .hex)
        try values.encode(rgba, forKey: .rgba)
        try values.encode(cmyk, forKey: .cmyk)
        try values.encode(dateSaved, forKey: .dateSaved)
        try values.encode(isFavorite, forKey: .isFavorite)
        try values.encode(ral, forKey: .ral)
        try values.encode(note, forKey: .note)
    }

    var shareText: String {
        var text = "\(ral.code) — \(ral.localizedName)\nHEX: \(hex)\nRGBA: \(rgb.rgbString) \(rgba.a)\nCMYK: \(rgb.cmykString)"
        if !note.isEmpty { text += "\n\(note)" }
        return text
    }
}
