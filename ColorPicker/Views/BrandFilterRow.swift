import SwiftUI

/// Row of pill buttons for picking one of the four bundled catalogs to
/// restrict `nearestCatalogMatch` to — shown on Camera/Photo while in
/// single-brand matching mode, hidden in all-brands mode (see each screen's
/// three-dots menu).
struct BrandFilterRow: View {
    @Binding var selectedCatalog: ColorCatalog

    private static let order: [ColorCatalog] = [.ral, .pantone, .ikea, .sherwinWilliams]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Self.order) { catalog in
                pill(catalog)
            }
        }
        .padding(.horizontal, 16)
    }

    private func pill(_ catalog: ColorCatalog) -> some View {
        let isSelected = selectedCatalog == catalog
        return Button(action: { selectedCatalog = catalog }) {
            Text(catalog.displayName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isSelected ? .white : Color(hex: "222330"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(isSelected ? Color.appAccent : Color.white.opacity(0.9))
                )
                .overlay {
                    if !isSelected {
                        Capsule().strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(SoftPressButtonStyle())
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}

#Preview {
    BrandFilterRow(selectedCatalog: .constant(.ral))
        .padding()
        .background(Color(.secondarySystemBackground))
}
