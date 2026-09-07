//
//  SavedColorsView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 5/9/26.
//

import SwiftUI

// MARK: - SavedColorsView

struct SavedColorsView: View {

    private enum Tab: Hashable {
        case colors, palettes
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(SavedColorsStore.self) private var savedColorsStore
    @Environment(PaletteStore.self) private var paletteStore

    @State private var selectedTab: Tab = .colors
    @State private var paletteToBrowse: Palette?
    @State private var showsCopiedToast = false

    @State private var isSelecting = false
    @State private var selectedColorIDs: Set<UUID> = []
    @State private var selectedPaletteIDs: Set<UUID> = []

    private var hasSelection: Bool {
        switch selectedTab {
        case .colors: !selectedColorIDs.isEmpty
        case .palettes: !selectedPaletteIDs.isEmpty
        }
    }

    private var selectionShareText: String {
        switch selectedTab {
        case .colors:
            savedColorsStore.savedColors.filter { selectedColorIDs.contains($0.id) }
                .map(\.shareText).joined(separator: "\n\n")
        case .palettes:
            paletteStore.palettes.filter { selectedPaletteIDs.contains($0.id) }
                .map(\.shareText).joined(separator: "\n\n")
        }
    }

    private var isAllSelected: Bool {
        switch selectedTab {
        case .colors:
            !savedColorsStore.savedColors.isEmpty && selectedColorIDs.count == savedColorsStore.savedColors.count
        case .palettes:
            !paletteStore.palettes.isEmpty && selectedPaletteIDs.count == paletteStore.palettes.count
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            segmentedControl
                .padding(.horizontal, 16)
                .padding(.top, 12)

            content
        }
        .background(Color(.systemBackground))
        .savedToast(isPresented: $showsCopiedToast, text: "Скопировано")
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isSelecting {
                    Button("Отмена", action: exitSelectionMode)
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
            if isSelecting {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: selectionShareText) {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                    .disabled(!hasSelection)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: toggleSelectAll) {
                        Image(systemName: isAllSelected ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundStyle(Color.tealAccent)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isSelecting {
                    Button(action: deleteSelected) {
                        Image(systemName: "trash")
                            .foregroundStyle(hasSelection ? .red : .secondary)
                    }
                    .disabled(!hasSelection)
                } else {
                    Button(action: { isSelecting = true }) {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .sheet(item: $paletteToBrowse) { palette in
            NavigationStack {
                PaletteDetailView(palette: palette)
            }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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

    private func segmentButton(tab: Tab, icon: String) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isSelected ? Color.tealAccent : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemBackground))
                        .opacity(isSelected ? 1 : 0)
                        .shadow(color: .black.opacity(isSelected ? 0.12 : 0), radius: 4, y: 2)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .colors:
            colorsTab
                .transition(.opacity.combined(with: .move(edge: .leading)))
        case .palettes:
            palettesTab
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    @ViewBuilder
    private var colorsTab: some View {
        if savedColorsStore.savedColors.isEmpty {
            emptyState(icon: "paintpalette", text: "Нет сохраненных цветов")
        } else {
            List {
                ForEach(savedColorsStore.savedColors) { entry in
                    HStack(spacing: 12) {
                        if isSelecting {
                            selectionIndicator(isSelected: selectedColorIDs.contains(entry.id))
                        }
                        ColorInfoCard(rgb: entry.rgb, ral: entry.ral,
                                      onCopied: isSelecting ? nil : { showsCopiedToast = true })
                        if !isSelecting {
                            ShareLink(item: entry.shareText) {
                                Label("Поделиться цветом", systemImage: "square.and.arrow.up")
                                    .labelStyle(.iconOnly)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelecting {
                            toggleColorSelection(entry.id)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onDelete { offsets in
                    savedColorsStore.remove(at: offsets)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var palettesTab: some View {
        if paletteStore.palettes.isEmpty {
            emptyState(icon: "square.stack", text: "Нет сохраненных палитр")
        } else {
            List {
                ForEach(paletteStore.palettes) { palette in
                    HStack(spacing: 12) {
                        if isSelecting {
                            selectionIndicator(isSelected: selectedPaletteIDs.contains(palette.id))
                        }
                        ColorStripView(colors: palette.colors.map(\.rgb))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelecting {
                            togglePaletteSelection(palette.id)
                        } else {
                            paletteToBrowse = palette
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onDelete { offsets in
                    paletteStore.remove(at: offsets)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 22))
            .foregroundStyle(isSelected ? Color.tealAccent : Color(.tertiaryLabel))
    }

    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Multi-select

    private func toggleColorSelection(_ id: UUID) {
        if selectedColorIDs.contains(id) {
            selectedColorIDs.remove(id)
        } else {
            selectedColorIDs.insert(id)
        }
    }

    private func togglePaletteSelection(_ id: UUID) {
        if selectedPaletteIDs.contains(id) {
            selectedPaletteIDs.remove(id)
        } else {
            selectedPaletteIDs.insert(id)
        }
    }

    private func toggleSelectAll() {
        switch selectedTab {
        case .colors:
            selectedColorIDs = isAllSelected ? [] : Set(savedColorsStore.savedColors.map(\.id))
        case .palettes:
            selectedPaletteIDs = isAllSelected ? [] : Set(paletteStore.palettes.map(\.id))
        }
    }

    private func deleteSelected() {
        switch selectedTab {
        case .colors:
            for entry in savedColorsStore.savedColors where selectedColorIDs.contains(entry.id) {
                savedColorsStore.remove(entry)
            }
        case .palettes:
            for palette in paletteStore.palettes where selectedPaletteIDs.contains(palette.id) {
                paletteStore.remove(palette)
            }
        }
        exitSelectionMode()
    }

    private func exitSelectionMode() {
        isSelecting = false
        selectedColorIDs.removeAll()
        selectedPaletteIDs.removeAll()
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
