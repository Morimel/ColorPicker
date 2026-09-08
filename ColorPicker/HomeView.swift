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

    private var optionsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
            ForEach(Array(HomeOption.gridOptions.enumerated()), id: \.element.id) { index, option in
                NavigationLink(value: option.destination) {
                    HomeOptionButton(option: option)
                }
                .buttonStyle(SoftPressButtonStyle())
                .softEntrance(delay: 0.05 * Double(index + 1))
            }
        }
    }

    private var savedButton: some View {
        NavigationLink(value: HomeDestination.saved) {
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

    var body: some View {
        VStack(spacing: 12) {
            if let artwork = option.artwork {
                LottieArtwork(asset: artwork)
                    .frame(width: 72, height: 72)
            }
            Text(option.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.3, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
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

    var body: some View {
        Group {
            if viewModel.palettes.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Палитры")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            LottieArtwork(asset: .palette)
                .frame(width: 132, height: 132)
            Text("Пока нет сохранённых палитр")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.palettes) { palette in
                    NavigationLink {
                        PaletteDetailView(palette: palette)
                    } label: {
                        PaletteRow(palette: palette)
                    }
                    .buttonStyle(SoftPressButtonStyle())
                }
            }
            .padding(16)
        }
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

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
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
