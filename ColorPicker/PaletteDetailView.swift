//
//  PaletteDetailView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 4/9/26.
//

import SwiftUI

// MARK: - PaletteDetailView

/// Shown either as a sheet over `PhotoColorPickerView` right after extracting
/// dominant colors (`.create`, offers a "+" to save the palette), or pushed
/// from `PalettesView` to browse a palette that's already saved (`.browse`,
/// read-only — no "+").
struct PaletteDetailView: View {

    enum Mode {
        case create(colors: [RGBColor])
        case browse(palette: Palette)
    }

    let mode: Mode
    var onSaved: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(PaletteStore.self) private var paletteStore

    /// Each swatch's nearest RAL match, computed per-color rather than reused
    /// from a single lookup.
    private var entries: [(rgb: RGBColor, ral: RALColor)] {
        switch mode {
        case .create(let colors):
            return colors.map { ($0, RALPalette.nearestRALColor(to: $0)) }
        case .browse(let palette):
            return palette.colors.map { ($0.rgb, $0.ral) }
        }
    }

    private var isCreateMode: Bool {
        if case .create = mode { return true }
        return false
    }

    private var browseTitle: String? {
        if case .browse(let palette) = mode { return palette.name }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header
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
        .navigationTitle(browseTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 12) {
            colorStrip

            if isCreateMode {
                Button(action: savePalette) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.tealAccent)
                }
            }
        }
    }

    private var colorStrip: some View {
        ColorStripView(colors: entries.map(\.rgb))
    }

    private func savePalette() {
        guard case .create(let colors) = mode else { return }
        let savedColors = colors.map { rgb in
            SavedColor(rgb: rgb, ral: RALPalette.nearestRALColor(to: rgb), note: "", createdAt: Date())
        }
        paletteStore.add(colors: savedColors)
        onSaved?()
        dismiss()
    }
}

// MARK: - Preview

#Preview("Create") {
    PaletteDetailView(mode: .create(colors: [
        RGBColor(r: 229, g: 190, b: 1),
        RGBColor(r: 205, g: 164, b: 52),
        RGBColor(r: 183, g: 217, b: 177),
        RGBColor(r: 87, g: 166, b: 57),
    ]))
    .environment(PaletteStore())
}

#Preview("Browse") {
    NavigationStack {
        PaletteDetailView(mode: .browse(palette: Palette(
            name: "Палитра 04.09.26",
            colors: [
                SavedColor(rgb: RGBColor(r: 229, g: 190, b: 1), ral: RALPalette.colors[1], note: "", createdAt: Date()),
                SavedColor(rgb: RGBColor(r: 205, g: 164, b: 52), ral: RALPalette.colors[2], note: "", createdAt: Date()),
            ],
            createdAt: Date()
        )))
        .environment(PaletteStore())
    }
}
