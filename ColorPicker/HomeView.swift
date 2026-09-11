//
//  HomeView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var gridWidth: CGFloat = 0
    @Binding var incomingURL: URL?

    init(incomingURL: Binding<URL?> = .constant(nil)) {
        _incomingURL = incomingURL
    }

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                        .softEntrance()

                    optionsGrid

                    savedButton
                        .softEntrance(delay: 0.25)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationDestination(for: HomeDestination.self) { destination in
                destination.view
            }
            .navigationDestination(for: UUID.self) { id in
                SavedColorDetailView(colorID: id)
            }
            .fullScreenCover(isPresented: $viewModel.showsPaywall) {
                PaywallView()
            }
        }
        .onChange(of: incomingURL, initial: true) { _, url in
            guard viewModel.handle(url: url) else { return }
            incomingURL = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Определитель цвета")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Выберите опцию для старта")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private static let gridSpacing: CGFloat = 20
    private static let cardAspectRatio: CGFloat = 0.88 // width / height

    private var cardHeight: CGFloat {
        let columnWidth = (gridWidth - Self.gridSpacing) / 2
        guard columnWidth > 0 else { return 150 }
        return columnWidth / Self.cardAspectRatio
    }

    private var optionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Self.gridSpacing), GridItem(.flexible())], spacing: Self.gridSpacing) {
            ForEach(Array(HomeOption.gridOptions.enumerated()), id: \.element.id) { index, option in
                Button(action: { viewModel.navigate(to: option.destination) }) {
                    HomeOptionButton(option: option, height: cardHeight)
                }
                .buttonStyle(SoftPressButtonStyle())
                .softEntrance(delay: 0.05 * Double(index + 1))
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { gridWidth = $0 })
    }

    private var savedButton: some View {
        Button(action: { viewModel.navigate(to: .saved) }) {
            Text(HomeOption.saved.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(HomeOption.saved.color)
                )
        }
        .buttonStyle(SoftPressButtonStyle())
        .padding(.bottom, 24)
    }
}

// MARK: - HomeOption

private struct HomeOptionButton: View {
    let option: HomeOption
    let height: CGFloat

    var body: some View {
        VStack(spacing: 16) {
            if let artwork = option.artwork {
                LottieArtwork(asset: artwork)
                    .frame(width: 64, height: 64)
            }
            Text(option.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(option.color)
        )
    }
}

struct HomeOption: Identifiable {
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    let destination: HomeDestination

    var id: HomeDestination { destination }

    var artwork: LottieArtwork.Asset? {
        switch destination {
        case .camera: .camera
        case .photo: .gallery
        case .converter: .converter
        case .palettes: .palette
        case .saved: nil
        }
    }

    static let camera = HomeOption(title: "Камера", icon: "camera.fill", color: Color(hex: "2E86AB"), destination: .camera)
    static let photo = HomeOption(title: "Фотогалерея", icon: "photo.on.rectangle", color: Color(hex: "4CAF7D"), destination: .photo)
    static let converter = HomeOption(title: "Конвертер", icon: "eyedropper", color: Color(hex: "A6B32A"), destination: .converter)
    static let palettes = HomeOption(title: "Палитры", icon: "square.grid.2x2.fill", color: Color(hex: "E38A2B"), destination: .palettes)
    static let saved = HomeOption(title: "Сохраненные", icon: "bookmark.fill", color: Color(hex: "A13B2E"), destination: .saved)

    static let gridOptions: [HomeOption] = [.camera, .photo, .converter, .palettes]
}

// MARK: - Navigation destinations

enum HomeDestination: Hashable {
    case camera
    case photo
    case converter
    case palettes
    case saved

    /// Every destination gets exactly one free visit (see
    /// `SubscriptionStore.canVisit`); camera/photo additionally lock their
    /// catalog-match name/code/hex after a brief teaser within that visit
    /// (see `CatalogMatchCard.locksWhenFree`).
    var gatedScreen: GatedScreen? {
        switch self {
        case .camera: .camera
        case .photo: .photo
        case .converter: .converter
        case .palettes: .palettes
        case .saved: .saved
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .camera:
            CameraColorPickerView()
        case .photo:
            PhotoColorPickerView()
        case .converter:
            ConverterView()
        case .palettes:
            PalettesView()
        case .saved:
            SavedColorsView()
        }
    }
}

// MARK: - Palettes

/// Thin wrapper: `@Environment` values aren't available until the view is in
/// the hierarchy, so the view model — which owns the store outright rather
/// than receiving it per call — is created once here and handed down.
struct PalettesView: View {
    @Environment(PaletteStore.self) private var paletteStore
    @State private var viewModel: PalettesViewModel?

    var body: some View {
        Group {
            if let viewModel {
                PalettesContent(viewModel: viewModel)
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
                viewModel = PalettesViewModel(store: paletteStore)
            }
        }
    }
}

private struct PalettesContent: View {
    let viewModel: PalettesViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pendingNewPalette: Palette?
    @State private var showsNewPalette = false
    @State private var pdfToShare: URL?
    @State private var showsPDFShareSheet = false

    var body: some View {
        Group {
            if viewModel.palettes.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .animation(reduceMotion ? nil : AppMotion.spring, value: viewModel.isSelecting)
        .navigationTitle("Палитры")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isSelecting)
        .toolbar {
            if viewModel.isSelecting {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена", action: viewModel.exitSelectionMode)
                        .foregroundStyle(Color.appAccent)
                }
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
                            .foregroundStyle(Color.appAccent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.deleteSelected) {
                        Image(systemName: "trash")
                            .foregroundStyle(viewModel.hasSelection() ? .red : .secondary)
                    }
                    .disabled(!viewModel.hasSelection())
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: createPalette) {
                        Label("Новая палитра", systemImage: "plus")
                    }
                }
                if !viewModel.palettes.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { viewModel.isSelecting = true }) {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showsPDFShareSheet) {
            if let pdfToShare {
                ShareSheet(activityItems: [pdfToShare])
            }
        }
        .navigationDestination(isPresented: $showsNewPalette) {
            if let pendingNewPalette {
                PaletteDetailView(palette: pendingNewPalette)
            }
        }
    }

    private func createPalette() {
        pendingNewPalette = viewModel.createPalette()
        showsNewPalette = true
    }

    private func exportSelectionPDF() {
        guard let url = viewModel.exportSelectionPDF() else { return }
        pdfToShare = url
        showsPDFShareSheet = true
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            LottieArtwork(asset: .palette)
                .frame(width: 132, height: 132)
            Text("Пока нет сохранённых палитр")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: createPalette) {
                Label("Новая палитра", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appAccent)
            .padding(.top, 8)
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.palettes) { palette in
                paletteRow(for: palette)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onDelete { offsets in
                viewModel.delete(at: offsets)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func paletteRow(for palette: Palette) -> some View {
        if viewModel.isSelecting {
            HStack(spacing: 14) {
                selectionIndicator(isSelected: viewModel.selectedPaletteIDs.contains(palette.id))
                PaletteRow(palette: palette)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.toggleSelection(palette.id)
            }
            .accessibilityAddTraits(viewModel.selectedPaletteIDs.contains(palette.id) ? .isSelected : [])
        } else {
            NavigationLink {
                PaletteDetailView(palette: palette)
            } label: {
                PaletteRow(palette: palette)
            }
        }
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 22))
            .foregroundStyle(isSelected ? Color.appAccent : Color(.tertiaryLabel))
    }
}

private struct PaletteRow: View {
    let palette: Palette

    var body: some View {
        HStack(spacing: 14) {
            ColorStripView(colors: palette.colors.prefix(6).map(\.rgb), height: 44, cornerRadius: 10)
                .frame(width: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(palette.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(palette.colors.count) цветов")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(SavedColorsStore())
        .environment(PaletteStore())
}
