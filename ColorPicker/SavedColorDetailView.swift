import SwiftUI

/// Thin wrapper: `@Environment` values aren't available until the view is in
/// the hierarchy, so the view model — which owns the store outright rather
/// than receiving it per call — is created once here and handed down.
struct SavedColorDetailView: View {
    let colorID: UUID
    @Environment(SavedColorsStore.self) private var store
    @State private var viewModel: SavedColorDetailViewModel?

    var body: some View {
        Group {
            if let viewModel {
                SavedColorDetailContent(viewModel: viewModel)
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
                viewModel = SavedColorDetailViewModel(colorID: colorID, store: store)
            }
        }
    }
}

private struct SavedColorDetailContent: View {
    @Bindable var viewModel: SavedColorDetailViewModel

    var body: some View {
        Group {
            if let color = viewModel.color {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.sRGB, red: color.rgba.r, green: color.rgba.g, blue: color.rgba.b, opacity: color.rgba.a))
                            .aspectRatio(2.2, contentMode: .fit)
                            .frame(maxHeight: 280)
                            .frame(maxWidth: .infinity)
                            .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(.secondary.opacity(0.2)) }
                        ColorInfoCard(rgb: color.rgb, ral: color.ral, onCopied: viewModel.markCopied)
                        ColorValuesSection(
                            hex: color.hex,
                            rgba: "\(color.rgb.r), \(color.rgb.g), \(color.rgb.b), \(color.rgba.a.formatted())",
                            cmyk: color.rgb.cmykString
                        )
                        if !color.note.isEmpty { Text(color.note) }
                        Text(color.dateSaved, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            viewModel.toggleFavorite()
                        } label: {
                            Label(color.isFavorite ? "Убрать из избранного" : "В избранное",
                                  systemImage: color.isFavorite ? "star.fill" : "star")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.tealAccent)
                        ShareLink(item: color.shareText) {
                            Label("Поделиться", systemImage: "square.and.arrow.up")
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 700, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .navigationTitle(color.hex)
            } else {
                ContentUnavailableView("Цвет не найден", systemImage: "paintpalette",
                                       description: Text("Возможно, этот цвет уже удалён из сохранённых."))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .savedToast(isPresented: $viewModel.showsCopiedToast, text: "Скопировано")
    }
}

// MARK: - Adaptive HEX/RGBA/CMYK values

/// Lays its three value fields out as columns when there's room, or stacks
/// them vertically on narrow widths / large Dynamic Type sizes — `ViewThatFits`
/// picks whichever variant actually fits without truncating.
private struct ColorValuesSection: View {
    let hex: String
    let rgba: String
    let cmyk: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 20) {
                ColorValueField(label: "HEX", value: hex)
                ColorValueField(label: "RGBA", value: rgba)
                ColorValueField(label: "CMYK", value: cmyk)
            }
            VStack(alignment: .leading, spacing: 16) {
                ColorValueField(label: "HEX", value: hex)
                ColorValueField(label: "RGBA", value: rgba)
                ColorValueField(label: "CMYK", value: cmyk)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(.secondarySystemBackground)))
    }
}

private struct ColorValueField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospaced().weight(.semibold))
                // No truncation at any Dynamic Type size — let the text wrap
                // and grow vertically instead of clipping horizontally.
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
