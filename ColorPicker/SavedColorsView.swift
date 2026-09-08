//
//  SavedColorsView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 5/9/26.
//

import SwiftUI

// MARK: - SavedColorsView

/// Thin wrapper: `@Environment` values aren't available until the view is in
/// the hierarchy, so the view model — which owns both stores outright rather
/// than receiving them per call — is created once here and handed down.
struct SavedColorsView: View {
    @Environment(SavedColorsStore.self) private var savedColorsStore
    @Environment(PaletteStore.self) private var paletteStore
    @State private var viewModel: SavedColorsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                SavedColorsContent(viewModel: viewModel)
            } else {
                // Never let this render as a truly empty view: inside a
                // NavigationStack, a view whose first frame has zero content
                // doesn't get `.task`/`.onAppear` delivered, so `viewModel`
                // would stay nil forever and the screen would stay blank.
                Color.clear
            }
        }
        .task {
            if viewModel == nil {
                viewModel = SavedColorsViewModel(savedColorsStore: savedColorsStore, paletteStore: paletteStore)
            }
        }
    }
}

// MARK: - SavedColorsContent

private struct SavedColorsContent: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Namespace private var tabHighlight

    @Bindable var viewModel: SavedColorsViewModel

    @State private var pdfToShare: URL?
    @State private var showsPDFShareSheet = false

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Group {
            if isRegularWidth {
                NavigationSplitView {
                    sidebar
                } detail: {
                    if let colorToBrowse = viewModel.colorToBrowse {
                        SavedColorDetailView(colorID: colorToBrowse)
                    } else {
                        ContentUnavailableView("Выберите цвет", systemImage: "paintpalette",
                                                description: Text("Цвет откроется здесь."))
                    }
                }
            } else {
                sidebar
                    .navigationDestination(item: $viewModel.colorToBrowse) { id in
                        SavedColorDetailView(colorID: id)
                    }
            }
        }
        .sheet(item: $viewModel.paletteToBrowse) { palette in
            NavigationStack {
                PaletteDetailView(palette: palette)
            }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Sidebar (Home-screen-sized column on iPad, full screen on iPhone)

    private var sidebar: some View {
        VStack(spacing: 16) {
            segmentedControl
                .padding(.horizontal, 16)
                .padding(.top, 12)

            content
        }
        .animation(reduceMotion ? nil : AppMotion.spring, value: viewModel.isSelecting)
        .background(Color(.systemBackground))
        .savedToast(isPresented: $viewModel.showsCopiedToast, text: "Скопировано")
        .sheet(isPresented: $showsPDFShareSheet) {
            if let pdfToShare {
                ShareSheet(activityItems: [pdfToShare])
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if viewModel.isSelecting {
                    Button("Отмена", action: viewModel.exitSelectionMode)
                        .foregroundStyle(Color.tealAccent)
                } else {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.primary)
                    }
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Сохраненные")
                    .font(.headline)
            }
            if viewModel.isSelecting {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ShareLink(item: viewModel.selectionShareText) {
                            Label("Поделиться текстом", systemImage: "text.alignleft")
                        }
                        Button {
                            exportSelectionPDF()
                        } label: {
                            Label("Экспортировать в PDF", systemImage: "doc.richtext")
                        }
                    } label: {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                    .disabled(!viewModel.hasSelection())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.toggleSelectAll) {
                        Image(systemName: viewModel.isAllSelected ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundStyle(Color.tealAccent)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isSelecting {
                    Button(action: viewModel.deleteSelected) {
                        Image(systemName: "trash")
                            .foregroundStyle(viewModel.hasSelection() ? .red : .secondary)
                    }
                    .disabled(!viewModel.hasSelection())
                } else {
                    Button(action: { viewModel.isSelecting = true }) {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    // MARK: Segmented control

    private var segmentedControl: some View {
        HStack(spacing: 4) {
            segmentButton(tab: .colors, icon: "square.grid.2x2")
            segmentButton(tab: .palettes, icon: "rectangle.grid.1x2")
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    private func segmentButton(tab: SavedColorsViewModel.Tab, icon: String) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            withAnimation(reduceMotion ? nil : AppMotion.spring) {
                viewModel.selectedTab = tab
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isSelected ? Color.tealAccent : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                            .matchedGeometryEffect(id: "selectedTab", in: tabHighlight)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.selectedTab {
        case .colors:
            colorsTab
                .transition(.opacity)
        case .palettes:
            palettesTab
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var colorsTab: some View {
        if viewModel.colors.isEmpty {
            emptyState(text: "Нет сохраненных цветов")
        } else if isRegularWidth {
            // iPad: a reflowing grid of compact swatches rather than full-width rows.
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                    ForEach(viewModel.colors) { entry in
                        Button {
                            if viewModel.isSelecting {
                                viewModel.toggleColorSelection(entry.id)
                            } else {
                                viewModel.colorToBrowse = entry.id
                            }
                        } label: {
                            SavedColorGridCell(color: entry, isSelected: viewModel.selectedColorIDs.contains(entry.id), showsSelection: viewModel.isSelecting)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(viewModel.selectedColorIDs.contains(entry.id) ? .isSelected : [])
                    }
                }
                .padding(16)
            }
        } else {
            List {
                ForEach(viewModel.colors) { entry in
                    HStack(spacing: 12) {
                        if viewModel.isSelecting {
                            selectionIndicator(isSelected: viewModel.selectedColorIDs.contains(entry.id))
                        }
                        ColorInfoCard(rgb: entry.rgb, ral: entry.ral,
                                      onCopied: viewModel.isSelecting ? nil : { viewModel.markCopied() })
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if viewModel.isSelecting {
                            viewModel.toggleColorSelection(entry.id)
                        } else {
                            viewModel.colorToBrowse = entry.id
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onDelete { offsets in
                    viewModel.removeColors(at: offsets)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var palettesTab: some View {
        if viewModel.palettes.isEmpty {
            emptyState(text: "Нет сохраненных палитр")
        } else if isRegularWidth {
            // iPad: a reflowing grid of palette swatch cards rather than full-width rows.
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                    ForEach(viewModel.palettes) { palette in
                        Button {
                            if viewModel.isSelecting {
                                viewModel.togglePaletteSelection(palette.id)
                            } else {
                                viewModel.paletteToBrowse = palette
                            }
                        } label: {
                            SavedPaletteGridCell(palette: palette, isSelected: viewModel.selectedPaletteIDs.contains(palette.id), showsSelection: viewModel.isSelecting)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(viewModel.selectedPaletteIDs.contains(palette.id) ? .isSelected : [])
                    }
                }
                .padding(16)
            }
        } else {
            List {
                ForEach(viewModel.palettes) { palette in
                    HStack(spacing: 12) {
                        if viewModel.isSelecting {
                            selectionIndicator(isSelected: viewModel.selectedPaletteIDs.contains(palette.id))
                        }
                        ColorStripView(colors: palette.colors.map(\.rgb))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if viewModel.isSelecting {
                            viewModel.togglePaletteSelection(palette.id)
                        } else {
                            viewModel.paletteToBrowse = palette
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onDelete { offsets in
                    viewModel.removePalettes(at: offsets)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func exportSelectionPDF() {
        guard let url = viewModel.exportSelectionPDF() else { return }
        pdfToShare = url
        showsPDFShareSheet = true
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 22))
            .foregroundStyle(isSelected ? Color.tealAccent : Color(.tertiaryLabel))
    }

    private func emptyState(text: String) -> some View {
        VStack(spacing: 12) {
            LottieArtwork(asset: .palette)
                .frame(width: 132, height: 132)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Grid cells (iPad)

private struct SavedColorGridCell: View {
    let color: SavedColor
    var isSelected = false
    var showsSelection = false

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: color.hex))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    if showsSelection {
                        selectionBadge(systemImage: isSelected ? "checkmark.circle.fill" : "circle", tinted: isSelected)
                    } else if color.isFavorite {
                        selectionBadge(systemImage: "star.fill", tinted: false)
                    }
                }
            Text(color.hex)
                .font(.caption.monospaced().weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(color.isFavorite ? "Избранный цвет" : "Цвет") \(color.hex)")
    }

    private func selectionBadge(systemImage: String, tinted: Bool) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tinted ? Color.tealAccent : .white)
            .padding(5)
            .background(.black.opacity(tinted ? 0 : 0.25), in: Circle())
            .padding(6)
    }
}

private struct SavedPaletteGridCell: View {
    let palette: Palette
    var isSelected = false
    var showsSelection = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ColorStripView(colors: palette.colors.prefix(6).map(\.rgb), height: 72, cornerRadius: 12)
                .overlay(alignment: .topTrailing) {
                    if showsSelection {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.tealAccent : .white)
                            .padding(5)
                            .background(.black.opacity(isSelected ? 0 : 0.25), in: Circle())
                            .padding(6)
                    }
                }
            Text(palette.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(palette.name)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SavedColorsView()
            .environment(SavedColorsStore())
            .environment(PaletteStore())
    }
}
