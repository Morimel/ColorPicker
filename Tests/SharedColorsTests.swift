import Foundation

@main
struct SharedColorsTests {
    @MainActor
    static func main() throws {
        func check(_ condition: @autoclosure () throws -> Bool, _ message: String = "Check failed") rethrows {
            let result = try condition()
            precondition(result, message)
        }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let legacyURL = root.appendingPathComponent("legacy.json")
        let sharedURL = root.appendingPathComponent("shared.json")
        let id = UUID()
        let rgb = RGBColor(r: 58, g: 123, b: 213)
        let date = Date(timeIntervalSinceReferenceDate: 123456)
        let entry = SavedColor(id: id, rgb: rgb, ral: RALPalette.nearestRALColor(to: rgb), note: "Original note", createdAt: date)
        let legacy: [String: Any] = ["id": id.uuidString, "rgb": ["r":58,"g":123,"b":213],
                                    "note":"Original note", "createdAt":123456]
        try JSONSerialization.data(withJSONObject: [legacy]).write(to: legacyURL)
        try SharedColorStorage.migrateIfNeeded(from: legacyURL, to: sharedURL)
        let migrated = try SharedColorStorage.read(from: sharedURL)
        precondition(migrated == [entry], "Legacy data must preserve ID, date, note and color")
        precondition(migrated[0].rgba.a == 1 && !migrated[0].isFavorite)
        precondition(migrated[0].hex == "#3A7BD5")
        precondition(abs(migrated[0].cmyk.k - (1 - 213.0/255)) < 0.000001)
        var invalid = try JSONSerialization.jsonObject(with: JSONEncoder().encode(entry)) as! [String: Any]
        invalid["rgba"] = ["r": 1e100, "g": 0, "b": 0, "a": 1]
        do {
            _ = try JSONDecoder().decode(SavedColor.self, from: JSONSerialization.data(withJSONObject: invalid))
            preconditionFailure("Invalid channels must be rejected before numeric conversion")
        } catch is DecodingError { }
        let black = SavedColor(rgb: RGBColor(r: 0,g: 0,b: 0), ral: RALPalette.colors[0], note: "", createdAt: date)
        precondition(black.cmyk == SavedColor.CMYK(c: 0,m: 0,y: 0,k: 1))
        try SharedColorStorage.write([], to: sharedURL)
        try SharedColorStorage.migrateIfNeeded(from: legacyURL, to: sharedURL)
        try check(try SharedColorStorage.read(from: sharedURL).isEmpty, "Migration must not resurrect deletions")
        var favorite = entry
        favorite.id = UUID()
        favorite.isFavorite = true
        favorite.dateSaved = date.addingTimeInterval(-500)
        var newest = entry
        newest.id = UUID()
        newest.dateSaved = date.addingTimeInterval(500)
        precondition(SharedColorStorage.prioritized([entry,newest,favorite]).map(\.id) == [favorite.id,newest.id,entry.id])
        try SharedColorStorage.write([favorite,newest], to: sharedURL)
        try check(try SharedColorStorage.read(from: sharedURL) == [favorite,newest])
        precondition(ColorDeepLink(url: ColorDeepLink.url(for: id)) == .color(id))
        precondition(ColorDeepLink(url: ColorDeepLink.savedURL) == .saved)
        for bad in ["https://color/\(id)","colorpicker://color/nope","colorpicker://color/\(id)/extra", "colorpicker://color/\(id)?x=1", "colorpicker://user@color/\(id)"] {
            precondition(ColorDeepLink(url: URL(string: bad)!) == nil)
        }
        let store = SavedColorsStore(fileURL: sharedURL)
        store.toggleFavorite(id: newest.id)
        try check(try SharedColorStorage.read(from: sharedURL).allSatisfy(\.isFavorite))
        store.remove(favorite)
        try check(try SharedColorStorage.read(from: sharedURL).map(\.id) == [newest.id])
        precondition(store.add(rgb: rgb, note: "New"))
        try check(try SharedColorStorage.read(from: sharedURL).count == 2)
        let badURL = root.appendingPathComponent("corrupt.json")
        let badData = Data("broken".utf8)
        try badData.write(to: badURL)
        let brokenStore = SavedColorsStore(fileURL: badURL)
        precondition(brokenStore.persistenceError != nil)
        precondition(!brokenStore.add(rgb: rgb))
        try check(try Data(contentsOf: badURL) == badData, "Corrupt data must not be overwritten")
        let failureStore = SavedColorsStore(fileURL: root.appendingPathComponent("missing-directory/colors.json"))
        precondition(!failureStore.add(rgb: rgb))
        precondition(failureStore.savedColors.isEmpty && failureStore.persistenceError != nil)
        print("PASS: migration, round-trip, color conversion, favorites, ordering, deep links, deletes, saves, corrupt data and write failures")
    }
}
