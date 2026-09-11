import SwiftUI

/// The "Unlock" pill that stands in for a single locked value (a name, a
/// code, a hex string, …) on the live camera/gallery capture cards.
/// `isCompact` shrinks it to sit inline on its own line instead of spanning
/// the row. Uses the same purple as the paywall's CTA/"best value" badge so
/// a crown+Unlock pill reads as the same "premium" affordance everywhere it
/// appears — `ColorInfoCard`'s name/code cover and `CatalogMatchCard`'s
/// separate name/code/hex covers alike.
struct UnlockPill: View {
    let action: () -> Void
    var isCompact: Bool = false

    private static let background = Color(hex: "8065EC")
    private static let crownColor = Color(hex: "FFD54A")

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Self.crownColor)
                Text("Unlock")
                    .foregroundStyle(.white)
            }
            .font(isCompact ? .caption : .subheadline.weight(.semibold))
            .padding(.horizontal, isCompact ? 10 : 14)
            .padding(.vertical, isCompact ? 5 : 8)
            .frame(maxWidth: isCompact ? nil : .infinity)
            .background(
                Capsule(style: .continuous).fill(Self.background)
            )
        }
        .buttonStyle(SoftPressButtonStyle())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        UnlockPill(action: {})
        UnlockPill(action: {}, isCompact: true)
    }
    .padding()
}
