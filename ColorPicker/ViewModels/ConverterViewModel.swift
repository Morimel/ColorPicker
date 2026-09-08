import Foundation

// MARK: - ConverterField

enum ConverterField: Hashable {
    case hex, r, g, b, c, m, y, k
}

// MARK: - ConverterViewModel

/// Owns the HEX/RGB/CMYK field text and the sync logic that keeps them all
/// consistent with `currentColor`, for `ConverterView`.
@Observable
final class ConverterViewModel {

    private let store: SavedColorsStore

    var currentColor = RGBColor(r: 0, g: 0, b: 0)
    var hasEnteredColor = false
    var showSavedToast = false
    var showsColorPicker = false

    var hexText = "#000000"
    var rText = "0"
    var gText = "0"
    var bText = "0"
    var cText = "0"
    var mText = "0"
    var yText = "0"
    var kText = "0"

    var nearestRAL: RALColor { RALPalette.nearestRALColor(to: currentColor) }

    init(store: SavedColorsStore) {
        self.store = store
    }

    // MARK: Sync logic

    func commit(field: ConverterField?) {
        guard let field else { return }
        switch field {
        case .hex:
            commitHex()
        case .r, .g, .b:
            commitRGB()
        case .c, .m, .y, .k:
            commitCMYK()
        }
    }

    private func commitHex() {
        guard let parsed = RGBColor(hex: hexText) else {
            syncFields(skipping: .hex)
            return
        }
        currentColor = parsed
        hasEnteredColor = true
        syncFields(skipping: .hex)
    }

    private func commitRGB() {
        let r = RGBColor.clampChannel(Int(rText) ?? currentColor.r)
        let g = RGBColor.clampChannel(Int(gText) ?? currentColor.g)
        let b = RGBColor.clampChannel(Int(bText) ?? currentColor.b)
        currentColor = RGBColor(r: r, g: g, b: b)
        hasEnteredColor = true
        syncFields(skipping: nil)
    }

    private func commitCMYK() {
        let existing = currentColor.cmyk
        let c = RGBColor.clampPercent(Int(cText) ?? existing.c)
        let m = RGBColor.clampPercent(Int(mText) ?? existing.m)
        let y = RGBColor.clampPercent(Int(yText) ?? existing.y)
        let k = RGBColor.clampPercent(Int(kText) ?? existing.k)
        currentColor = RGBColor(c: c, m: m, y: y, k: k)
        hasEnteredColor = true
        syncFields(skipping: nil)
    }

    /// Refreshes every field from `currentColor`, except the field the user
    /// is still actively editing (so we don't stomp on the exact text they
    /// typed until they move on).
    func syncFields(skipping field: ConverterField?) {
        if field != .hex { hexText = currentColor.hexString }
        if field != .r { rText = "\(currentColor.r)" }
        if field != .g { gText = "\(currentColor.g)" }
        if field != .b { bText = "\(currentColor.b)" }

        let cmyk = currentColor.cmyk
        if field != .c { cText = "\(cmyk.c)" }
        if field != .m { mText = "\(cmyk.m)" }
        if field != .y { yText = "\(cmyk.y)" }
        if field != .k { kText = "\(cmyk.k)" }
    }

    /// Applies a color chosen from the system color picker sheet.
    func applyPickedColor(_ color: RGBColor) {
        currentColor = color
        hasEnteredColor = true
        syncFields(skipping: nil)
    }

    // MARK: Save

    func save(onSaved: @escaping () -> Void) {
        guard store.add(rgb: currentColor, note: "") else { return }
        showSavedToast = true
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            onSaved()
        }
    }
}
