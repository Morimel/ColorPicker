import SwiftUI

/// Thin wrapper: `@Environment` values aren't available until the view is in
/// the hierarchy, so the view model — which owns both stores outright rather
/// than receiving them per call — is created once here and handed down.
struct AddPaletteColorsView: View {
    let paletteID: UUID

    @Environment(PaletteStore.self) private var paletteStore
    @Environment(SavedColorsStore.self) private var savedColorsStore
    @State private var viewModel: AddPaletteColorsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                AddPaletteColorsContent(viewModel: viewModel)
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
                viewModel = AddPaletteColorsViewModel(paletteID: paletteID, paletteStore: paletteStore, savedColorsStore: savedColorsStore)
            }
        }
    }
}

private struct AddPaletteColorsContent: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AddPaletteColorsViewModel
    @State private var showsCatalogBrowser = false

    var body: some View {
        NavigationStack {
            List {
                Section("Новый цвет") {
                    TextField("HEX, например #A6B32A", text: $viewModel.hexText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    if let rgb = viewModel.customRGB {
                        ColorInfoCard(rgb: rgb, ral: RALPalette.nearestRALColor(to: rgb))
                    } else if viewModel.hasHexInput {
                        Text("Введите HEX из 6 символов: 0–9, A–F.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        showsCatalogBrowser = true
                    } label: {
                        Label("Обзор каталога цветов", systemImage: "square.grid.3x3.fill")
                    }
                }

                Section("Сохранённые цвета") {
                    if viewModel.savedColors.isEmpty {
                        Text("Нет сохранённых цветов. Добавьте новый цвет по HEX выше.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.savedColors) { entry in
                        Button {
                            viewModel.toggleSelection(entry.id)
                        } label: {
                            HStack {
                                ColorInfoCard(rgb: entry.rgb, ral: entry.ral)
                                Image(systemName: viewModel.selectedIDs.contains(entry.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(Color.appAccent)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(viewModel.selectedIDs.contains(entry.id) ? .isSelected : [])
                    }
                }
            }
            .navigationTitle("Добавить цвета")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить (\(viewModel.colorsToAdd.count))") {
                        viewModel.confirm()
                        dismiss()
                    }
                    .disabled(viewModel.colorsToAdd.isEmpty || (viewModel.hasHexInput && viewModel.customRGB == nil))
                }
            }
            .sheet(isPresented: $showsCatalogBrowser) {
                ColorCatalogBrowserView { rgb in
                    viewModel.addCatalogColorToPalette(rgb)
                }
            }
        }
    }
}
