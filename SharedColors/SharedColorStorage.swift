import Foundation

/// The app is the sole writer; widgets read atomic snapshots.
enum SharedColorStorage {
    static let appGroupID = "group.com.IsaMelsov.ColorPicker"
    static let recentWidgetKind = "RecentColorsWidget"
    static let lastWidgetKind = "LastColorWidget"

    static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("savedColors.json")
    }

    static func read(from url: URL) throws -> [SavedColor] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([SavedColor].self, from: Data(contentsOf: url))
    }

    static func write(_ colors: [SavedColor], to url: URL) throws {
        let data = try JSONEncoder().encode(colors)
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }

    /// Never replace an existing shared store, including an intentionally empty one.
    static func migrateIfNeeded(from legacyURL: URL, to sharedURL: URL) throws {
        guard !FileManager.default.fileExists(atPath: sharedURL.path),
              FileManager.default.fileExists(atPath: legacyURL.path) else { return }
        try write(read(from: legacyURL), to: sharedURL)
    }

    static func prioritized(_ colors: [SavedColor]) -> [SavedColor] {
        colors.sorted {
            if $0.isFavorite != $1.isFavorite { return $0.isFavorite }
            if $0.dateSaved != $1.dateSaved { return $0.dateSaved > $1.dateSaved }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}

enum ColorDeepLink: Equatable {
    case color(UUID)
    case saved

    static let savedURL = URL(string: "colorpicker://saved")!

    static func url(for id: UUID) -> URL {
        URL(string: "colorpicker://color/\(id.uuidString)")!
    }

    init?(url: URL) {
        guard url.scheme?.lowercased() == "colorpicker",
              url.user == nil, url.password == nil, url.port == nil,
              url.query == nil, url.fragment == nil else { return nil }
        let components = url.pathComponents.filter { $0 != "/" }
        if url.host == "saved", components.isEmpty {
            self = .saved
        } else if url.host == "color", components.count == 1, let id = UUID(uuidString: components[0]) {
            self = .color(id)
        } else {
            return nil
        }
    }
}
