//
//  PaletteStore.swift
//  ColorPicker
//
//  Created by Isa Melsov on 4/9/26.
//

import Foundation
import SwiftUI

// MARK: - Palette

struct Palette: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var colors: [SavedColor]
    var createdAt: Date

    var shareText: String {
        name + "\n\n" + colors.map(\.shareText).joined(separator: "\n\n")
    }

    static func generatedName(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return String(localized: "Палитра \(formatter.string(from: date))")
    }
}

// MARK: - PaletteStore

@Observable
final class PaletteStore {

    private(set) var palettes: [Palette] = []

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        load()
    }

    @discardableResult
    func add(colors: [SavedColor], name: String? = nil) -> Palette {
        let palette = Palette(name: name ?? Palette.generatedName(), colors: colors, createdAt: Date())
        palettes.insert(palette, at: 0)
        save()
        return palette
    }

    func add(colors: [SavedColor], to paletteID: UUID) {
        guard !colors.isEmpty,
              let index = palettes.firstIndex(where: { $0.id == paletteID }) else { return }
        palettes[index].colors.append(contentsOf: colors)
        save()
    }

    func remove(_ palette: Palette) {
        palettes.removeAll { $0.id == palette.id }
        save()
    }

    func remove(at offsets: IndexSet) {
        palettes.remove(atOffsets: offsets)
        save()
    }

    func rename(_ palette: Palette, to name: String) {
        guard let index = palettes.firstIndex(where: { $0.id == palette.id }) else { return }
        palettes[index].name = name
        save()
    }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        palettes = (try? JSONDecoder().decode([Palette].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(palettes) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func defaultFileURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("palettes.json")
    }
}
