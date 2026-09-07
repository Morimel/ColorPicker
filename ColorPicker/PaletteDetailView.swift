//
//  PaletteDetailView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 4/9/26.
//

import SwiftUI

// MARK: - PaletteDetailView

/// Browse, share, and extend a saved palette.
struct PaletteDetailView: View {

    let palette: Palette

    @Environment(PaletteStore.self) private var paletteStore
    @State private var showsAddColors = false
    @State private var showsCopiedToast = false

    private var currentPalette: Palette {
        paletteStore.palettes.first { $0.id == palette.id } ?? palette
    }

    private var entries: [(rgb: RGBColor, ral: RALColor)] {
        currentPalette.colors.map { ($0.rgb, $0.ral) }
    }

    var body: some View {
        VStack(spacing: 0) {
            colorStrip
                .padding(.horizontal, 16)
                .padding(.top, 20)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                        ColorInfoCard(rgb: entry.rgb, ral: entry.ral,
                                      onCopied: { showsCopiedToast = true })
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(currentPalette.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: currentPalette.shareText) {
                    Label("Поделиться палитрой", systemImage: "square.and.arrow.up")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                showsAddColors = true
            } label: {
                Label("Добавить цвета", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.tealAccent)
            .padding(16)
            .background(.regularMaterial)
        }
        .sheet(isPresented: $showsAddColors) {
            AddPaletteColorsView(paletteID: palette.id)
        }
        .savedToast(isPresented: $showsCopiedToast, text: "Скопировано")
    }

    private var colorStrip: some View {
        ColorStripView(colors: entries.map(\.rgb))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PaletteDetailView(palette: Palette(
            name: "Палитра 04.09.26",
            colors: [
                SavedColor(rgb: RGBColor(r: 229, g: 190, b: 1), ral: RALPalette.colors[1], note: "", createdAt: Date()),
                SavedColor(rgb: RGBColor(r: 205, g: 164, b: 52), ral: RALPalette.colors[2], note: "", createdAt: Date()),
            ],
            createdAt: Date()
        ))
        .environment(PaletteStore())
        .environment(SavedColorsStore())
    }
}
