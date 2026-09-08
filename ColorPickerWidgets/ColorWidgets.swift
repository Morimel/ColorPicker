import SwiftUI
import WidgetKit

struct ColorTimelineEntry: TimelineEntry {
    let date: Date
    let colors: [SavedColor]
    var isUnavailable = false

    static var preview: Self {
        let samples = [RGBColor(r: 58, g: 123, b: 213), RGBColor(r: 76, g: 175, b: 125),
                       RGBColor(r: 227, g: 138, b: 43), RGBColor(r: 161, g: 59, b: 46)]
        return Self(date: Date(), colors: samples.map {
            SavedColor(rgb: $0, ral: RALPalette.nearestRALColor(to: $0), note: "", createdAt: Date())
        })
    }
}

struct SavedColorsProvider: TimelineProvider {
    func placeholder(in context: Context) -> ColorTimelineEntry { .preview }

    func getSnapshot(in context: Context, completion: @escaping (ColorTimelineEntry) -> Void) {
        completion(context.isPreview ? .preview : load(for: context.family))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ColorTimelineEntry>) -> Void) {
        let entry = load(for: context.family)
        // App writes request an earlier reload; the system ultimately schedules updates.
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
    }

    /// .systemExtraLarge (iPad only) shows a denser grid, so it needs more
    /// entries preloaded than the other families.
    private func load(for family: WidgetFamily) -> ColorTimelineEntry {
        let limit = family == .systemExtraLarge ? 8 : 4
        guard let url = SharedColorStorage.fileURL else {
            return ColorTimelineEntry(date: Date(), colors: [], isUnavailable: true)
        }
        do {
            let colors = try SharedColorStorage.read(from: url)
            return ColorTimelineEntry(date: Date(), colors: Array(SharedColorStorage.prioritized(colors).prefix(limit)))
        } catch {
            return ColorTimelineEntry(date: Date(), colors: [], isUnavailable: true)
        }
    }
}

struct RecentColorsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedColorStorage.recentWidgetKind, provider: SavedColorsProvider()) { entry in
            RecentColorsWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color(.systemBackground) }
        }
        .configurationDisplayName("Сохранённые цвета")
        .description("Избранные и последние сохранённые цвета — всегда под рукой.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemExtraLarge])
    }
}

struct LastColorWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedColorStorage.lastWidgetKind, provider: SavedColorsProvider()) { entry in
            LastColorWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Последний цвет")
        .description("Избранный или последний сохранённый цвет на экране блокировки.")
        .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}

@main
struct ColorPickerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RecentColorsWidget()
        LastColorWidget()
    }
}
