import SwiftUI
import WidgetKit

/// Shared by the Home Screen, Lock Screen and StandBy presentations.
struct WidgetColorSwatch: View {
    let color: SavedColor
    var circular = false
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var fill: Color {
        if renderingMode == .fullColor {
            return Color(.sRGB, red: color.rgba.r, green: color.rgba.g, blue: color.rgba.b, opacity: color.rgba.a)
        }
        return .primary
    }

    var body: some View {
        Group {
            if circular {
                Circle()
                    .fill(fill)
                    .overlay { Circle().strokeBorder(.primary.opacity(0.25), lineWidth: 1) }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(fill)
                    .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.15), lineWidth: 1) }
            }
        }
        .accessibilityLabel("Цвет \(color.hex)")
    }
}

struct WidgetSwatchColumn: View {
    let color: SavedColor
    var compact = false

    var body: some View {
        VStack(spacing: 8) {
            WidgetColorSwatch(color: color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(color.hex)
                .font(.system(compact ? .caption2 : .caption, design: .monospaced, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(color.isFavorite ? "Избранный цвет \(color.hex)" : "Цвет \(color.hex)")
    }
}

struct RecentColorsWidgetView: View {
    let entry: ColorTimelineEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        RecentColorsContent(entry: entry, family: family)
    }
}

struct RecentColorsContent: View {
    let entry: ColorTimelineEntry
    let family: WidgetFamily

    var body: some View {
        Group {
            if let first = entry.colors.first {
                switch family {
                case .systemExtraLarge:
                    // iPad only: a denser grid instead of just stretching the
                    // medium row, so the extra width actually shows more colors.
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 12) {
                        ForEach(entry.colors.prefix(8)) { color in
                            Link(destination: ColorDeepLink.url(for: color.id)) {
                                WidgetSwatchColumn(color: color, compact: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                case .systemMedium:
                    HStack(spacing: 10) {
                        ForEach(entry.colors.prefix(4)) { color in
                            Link(destination: ColorDeepLink.url(for: color.id)) {
                                WidgetSwatchColumn(color: color, compact: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                default:
                    // StandBy hosts systemSmall, using this same shared swatch column.
                    WidgetSwatchColumn(color: first)
                }
            } else {
                WidgetEmptyState(isUnavailable: entry.isUnavailable)
            }
        }
        .widgetURL(entry.colors.first.map { ColorDeepLink.url(for: $0.id) } ?? ColorDeepLink.savedURL)
    }
}

struct LastColorWidgetView: View {
    let entry: ColorTimelineEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        LastColorContent(entry: entry, family: family)
    }
}

struct LastColorContent: View {
    let entry: ColorTimelineEntry
    let family: WidgetFamily
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        Group {
            if family == .accessoryInline {
                if let hex = entry.colors.first?.hex {
                    Text(hex)
                } else if entry.isUnavailable {
                    Text(String(localized: "Откройте приложение"))
                } else {
                    Text(String(localized: "Сохраните цвет"))
                }
            } else if let color = entry.colors.first {
                ZStack {
                    AccessoryWidgetBackground()
                    WidgetColorSwatch(color: color, circular: true)
                        .padding(7)
                    // Lock Screen normally uses monochrome/vibrant rendering. Keep
                    // an identity cue readable even when the actual hue is removed.
                    if renderingMode != .fullColor {
                        Image(systemName: color.isFavorite ? "star.fill" : "paintpalette.fill")
                            .font(.title3)
                            .foregroundStyle(.black)
                            .blendMode(.destinationOut)
                    }
                }
                .compositingGroup()
                .accessibilityLabel("Цвет \(color.hex)")
            } else {
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: entry.isUnavailable ? "arrow.clockwise" : "plus")
                }
                .accessibilityLabel(entry.isUnavailable ? "Откройте приложение" : "Сохраните первый цвет")
            }
        }
        .widgetURL(entry.colors.first.map { ColorDeepLink.url(for: $0.id) } ?? ColorDeepLink.savedURL)
    }
}

struct WidgetEmptyState: View {
    var isUnavailable = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isUnavailable ? "arrow.clockwise" : "paintpalette")
                .font(.title2)
            Text(isUnavailable ? "Откройте приложение" : "Сохраните первый цвет")
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Small", as: .systemSmall) {
    RecentColorsWidget()
} timeline: {
    ColorTimelineEntry.preview
    ColorTimelineEntry(date: Date(), colors: [])
}

#Preview("Extra Large", as: .systemExtraLarge) {
    RecentColorsWidget()
} timeline: {
    ColorTimelineEntry(date: Date(), colors: [
        RGBColor(r: 58, g: 123, b: 213), RGBColor(r: 76, g: 175, b: 125),
        RGBColor(r: 227, g: 138, b: 43), RGBColor(r: 161, g: 59, b: 46),
        RGBColor(r: 109, g: 63, b: 91), RGBColor(r: 15, g: 67, b: 54),
        RGBColor(r: 205, g: 164, b: 52), RGBColor(r: 41, g: 49, b: 51),
    ].map { SavedColor(rgb: $0, ral: RALPalette.nearestRALColor(to: $0), note: "", createdAt: Date()) })
    ColorTimelineEntry(date: Date(), colors: [])
}

#Preview("Medium", as: .systemMedium) {
    RecentColorsWidget()
} timeline: {
    ColorTimelineEntry.preview
    ColorTimelineEntry(date: Date(), colors: Array(ColorTimelineEntry.preview.colors.prefix(1)))
    ColorTimelineEntry(date: Date(), colors: [])
}

#Preview("Circular", as: .accessoryCircular) {
    LastColorWidget()
} timeline: {
    ColorTimelineEntry.preview
    ColorTimelineEntry(date: Date(), colors: [])
}

#Preview("Inline", as: .accessoryInline) {
    LastColorWidget()
} timeline: {
    ColorTimelineEntry.preview
    ColorTimelineEntry(date: Date(), colors: [])
}
