import SwiftUI

/// Sheet for browsing the four bundled color catalogs (Pantone, IKEA, RAL, Sherwin-Williams)
/// and picking one color out of them.
///
/// The view only binds to each `ColorCatalogViewModel`'s `@Published` state and calls its
/// methods — it never touches a catalog array or a store directly. Picking a swatch reports
/// the choice up through `onColorPicked`; the caller decides what that pick means (populate
/// the color editor vs. add straight to the active palette) and names its own intent method
/// accordingly, per `AddPaletteColorsViewModel.addCatalogColorToPalette(_:)`.
struct ColorCatalogBrowserView: View {
    let onColorPicked: (RGBColor) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedCatalog: ColorCatalog = .pantone

    @StateObject private var pantoneViewModel = ColorCatalogViewModel(catalog: PantoneColor.pantonePalette)
    @StateObject private var ikeaViewModel = ColorCatalogViewModel(catalog: IKEAColor.ikeaPalette)
    @StateObject private var ralViewModel = ColorCatalogViewModel(catalog: RALCatalogColor.classic)
    @StateObject private var sherwinWilliamsViewModel = ColorCatalogViewModel(catalog: SherwinWilliamsColor.sherwinWilliamsPalette)

    private static let columns = [GridItem(.adaptive(minimum: 92), spacing: 14)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                catalogPicker
                searchField

                ScrollView {
                    LazyVGrid(columns: Self.columns, spacing: 18) {
                        switch selectedCatalog {
                        case .pantone: grid(pantoneViewModel)
                        case .ikea: grid(ikeaViewModel)
                        case .ral: grid(ralViewModel)
                        case .sherwinWilliams: grid(sherwinWilliamsViewModel)
                        }
                    }
                    .padding(16)
                }
            }
            .padding(.top, 12)
            .background(Color(.systemBackground))
            .navigationTitle("Каталог цветов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }

    private var catalogPicker: some View {
        Picker("Каталог", selection: $selectedCatalog) {
            ForEach(ColorCatalog.allCases) { catalog in
                Text(catalog.displayName).tag(catalog)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Поиск по названию", text: activeSearchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !activeSearchText.wrappedValue.isEmpty {
                Button {
                    activeSearchText.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 16)
    }

    private var activeSearchText: Binding<String> {
        switch selectedCatalog {
        case .pantone: $pantoneViewModel.searchText
        case .ikea: $ikeaViewModel.searchText
        case .ral: $ralViewModel.searchText
        case .sherwinWilliams: $sherwinWilliamsViewModel.searchText
        }
    }

    @ViewBuilder
    private func grid<T: ColorDataProtocol>(_ viewModel: ColorCatalogViewModel<T>) -> some View {
        ForEach(viewModel.filteredColors) { color in
            Button {
                pick(color, in: viewModel)
            } label: {
                ColorSwatchView(hex: color.hex, name: color.name,
                                 isSelected: viewModel.selectedColor?.id == color.id)
            }
            .buttonStyle(SoftPressButtonStyle())
        }
    }

    private func pick<T: ColorDataProtocol>(_ color: T, in viewModel: ColorCatalogViewModel<T>) {
        viewModel.selectedColor = color
        onColorPicked(RGBColor(r: color.rgb.r, g: color.rgb.g, b: color.rgb.b))
        dismiss()
    }
}

#Preview {
    ColorCatalogBrowserView(onColorPicked: { _ in })
}
