//
//  HomeView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    optionsGrid

                    savedButton
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
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            ForEach(HomeOption.gridOptions) { option in
                NavigationLink(value: option.destination) {
                    HomeOptionButton(option: option)
                }
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
        .padding(.bottom, 24)
    }
}

// MARK: - HomeOption

private struct HomeOptionButton: View {
    let option: HomeOption

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: option.icon)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white)
            Text(option.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(option.color)
        )
    }
}

struct HomeOption: Identifiable {
    let title: String
    let icon: String
    let color: Color
    let destination: HomeDestination

    var id: String { title }

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

// MARK: - Stub views

struct StubScreen: View {
    let title: String

    var body: some View {
        Text("Coming soon")
            .font(.title3)
            .foregroundStyle(.secondary)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView: View {
    var body: some View {
        StubScreen(title: "Настройки")
    }
}

struct PalettesView: View {
    @Environment(PaletteStore.self) private var paletteStore

    var body: some View {
        Group {
            if paletteStore.palettes.isEmpty {
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
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Пока нет сохранённых палитр")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(paletteStore.palettes) { palette in
                    NavigationLink {
                        PaletteDetailView(mode: .browse(palette: palette))
                    } label: {
                        PaletteRow(palette: palette)
                    }
                    .buttonStyle(.plain)
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
