import SwiftUI

/// Read-only preview of the colors captured so far on Camera/Photo, before
/// they're committed to a saved palette — tapping the strip at the bottom of
/// either screen's result section opens this. Mirrors `PaletteDetailView`'s
/// strip-then-card-list layout, minus its editing/share tools, since there's
/// nothing persisted yet to add to or share.
struct CapturedColorsSheet: View {
    let entries: [(rgb: RGBColor, ral: RALColor)]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ColorStripView(colors: entries.map(\.rgb))
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                            ColorInfoCard(rgb: entry.rgb, ral: entry.ral)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Захваченные цвета")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CapturedColorsSheet(entries: [
        (RGBColor(r: 229, g: 190, b: 1), RALPalette.colors[1]),
        (RGBColor(r: 205, g: 164, b: 52), RALPalette.colors[2]),
    ])
}
