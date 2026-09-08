//
//  PaletteDetailView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 4/9/26.
//

import SwiftUI

// MARK: - PaletteDetailView

/// Browse, share, and extend a saved palette. Thin wrapper: `@Environment`
/// values aren't available until the view is in the hierarchy, so the view
/// model — which owns the store outright rather than receiving it per call —
/// is created once here and handed down.
struct PaletteDetailView: View {
    let palette: Palette

    @Environment(PaletteStore.self) private var paletteStore
    @State private var viewModel: PaletteDetailViewModel?

    var body: some View {
        Group {
            if let viewModel {
                PaletteDetailContent(viewModel: viewModel)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = PaletteDetailViewModel(palette: palette, store: paletteStore)
            }
        }
    }
}

// MARK: - PaletteDetailContent

private struct PaletteDetailContent: View {
    @Bindable var viewModel: PaletteDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            colorStrip
                .padding(.horizontal, 16)
                .padding(.top, 20)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(viewModel.entries.enumerated()), id: \.offset) { _, entry in
                        ColorInfoCard(rgb: entry.rgb, ral: entry.ral,
                                      onCopied: viewModel.markCopied)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(viewModel.currentPalette.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: viewModel.currentPalette.shareText) {
                    Label("Поделиться палитрой", systemImage: "square.and.arrow.up")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.showsAddColors = true
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
        .sheet(isPresented: $viewModel.showsAddColors) {
            AddPaletteColorsView(paletteID: viewModel.currentPalette.id)
        }
        .savedToast(isPresented: $viewModel.showsCopiedToast, text: "Скопировано")
    }

    private var colorStrip: some View {
        ColorStripView(colors: viewModel.entries.map(\.rgb))
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
