import SwiftUI

/// Shows the closest match to a sampled/converted color across the four bundled
/// catalogs (Pantone/IKEA/RAL/Sherwin-Williams) — used by Converter, Camera, and
/// Photo alongside `ColorInfoCard`'s RAL-starter-set match.
struct CatalogMatchCard: View {
    let match: NearestCatalogMatch

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: match.hex))
                .frame(width: 56, height: 56)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(match.catalog.displayName.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.tealAccent)
                Text(match.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(match.code)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Hex: \(match.hex)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    CatalogMatchCard(match: NearestCatalogMatch(catalog: .pantone, name: "Signal Blue", code: "Pantone 042", hex: "#1E3F66"))
        .padding()
}
