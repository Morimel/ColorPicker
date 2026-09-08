import Foundation
import SwiftUI
import WidgetKit

@Observable
final class SavedColorsStore {
    private(set) var savedColors: [SavedColor] = []
    var persistenceError: String?
    private let fileURL: URL
    private let refreshWidgets: Bool
    private var canWrite = true

    init(fileURL: URL? = nil) {
        let legacyURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("savedColors.json")
        let sharedURL = fileURL == nil ? SharedColorStorage.fileURL : nil
        self.fileURL = fileURL ?? sharedURL ?? legacyURL
        refreshWidgets = fileURL == nil && sharedURL != nil
        do {
            if let sharedURL {
                try SharedColorStorage.migrateIfNeeded(from: legacyURL, to: sharedURL)
            }
            savedColors = try SharedColorStorage.read(from: self.fileURL)
            if refreshWidgets { reloadWidgets() }
            if fileURL == nil && sharedURL == nil {
                persistenceError = String(localized: "Цвета сохраняются на устройстве, но общий доступ для виджетов недоступен.")
            }
        } catch {
            // Keep corrupt or inaccessible data intact; do not overwrite it with an empty list.
            canWrite = false
            persistenceError = String(localized: "Не удалось прочитать сохранённые цвета. Попробуйте открыть приложение снова.")
        }
    }

    @discardableResult
    func add(rgb: RGBColor, note: String = "") -> Bool {
        let entry = SavedColor(rgb: rgb, ral: RALPalette.nearestRALColor(to: rgb), note: note, createdAt: Date())
        return commit([entry] + savedColors)
    }

    @discardableResult
    func add(_ entries: [SavedColor]) -> Bool {
        commit(entries.reversed() + savedColors)
    }

    func remove(_ entry: SavedColor) {
        commit(savedColors.filter { $0.id != entry.id })
    }

    func remove(at offsets: IndexSet) {
        var updated = savedColors
        updated.remove(atOffsets: offsets)
        commit(updated)
    }

    func toggleFavorite(id: UUID) {
        var updated = savedColors
        guard let index = updated.firstIndex(where: { $0.id == id }) else { return }
        updated[index].isFavorite.toggle()
        commit(updated)
    }

    @discardableResult
    private func commit(_ colors: [SavedColor]) -> Bool {
        guard canWrite else {
            persistenceError = String(localized: "Сохранённые цвета недоступны. Откройте приложение снова перед изменением.")
            return false
        }
        do {
            try SharedColorStorage.write(colors, to: fileURL)
            savedColors = colors
            if refreshWidgets { reloadWidgets() }
            return true
        } catch {
            persistenceError = String(localized: "Не удалось сохранить изменения. Попробуйте ещё раз.")
            return false
        }
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: SharedColorStorage.recentWidgetKind)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedColorStorage.lastWidgetKind)
    }
}
