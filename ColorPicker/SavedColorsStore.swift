//
//  SavedColorsStore.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import Foundation
import SwiftUI

// MARK: - SavedColor

struct SavedColor: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var rgb: RGBColor
    var ral: RALColor
    var note: String
    var createdAt: Date
}

// MARK: - SavedColorsStore

@Observable
final class SavedColorsStore {

    private(set) var savedColors: [SavedColor] = []

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        load()
    }

    func add(rgb: RGBColor, note: String = "") {
        let ral = RALPalette.nearestRALColor(to: rgb)
        let entry = SavedColor(rgb: rgb, ral: ral, note: note, createdAt: Date())
        savedColors.insert(entry, at: 0)
        save()
    }

    func remove(_ entry: SavedColor) {
        savedColors.removeAll { $0.id == entry.id }
        save()
    }

    func remove(at offsets: IndexSet) {
        savedColors.remove(atOffsets: offsets)
        save()
    }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        savedColors = (try? JSONDecoder().decode([SavedColor].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(savedColors) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func defaultFileURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("savedColors.json")
    }
}
