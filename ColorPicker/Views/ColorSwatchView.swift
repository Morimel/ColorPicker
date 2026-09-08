import SwiftUI

/// A compact grid cell for one catalog color: swatch, name, hex. Used by
/// `ColorCatalogBrowserView`'s `LazyVGrid` across all four catalogs.
struct ColorSwatchView: View {
    let hex: String
    let name: String
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: hex))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isSelected ? Color.tealAccent : Color(.separator),
                                      lineWidth: isSelected ? 3 : 0.5)
                }

            Text(name)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(hex.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ColorSwatchView(hex: "#2E86AB", name: "Traffic blue", isSelected: true)
        .frame(width: 100)
        .padding()
}
