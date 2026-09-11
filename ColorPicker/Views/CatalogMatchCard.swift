import SwiftUI

/// Shows the closest match to a sampled/converted color across the four bundled
/// catalogs (Pantone/IKEA/RAL/Sherwin-Williams) — used by Converter, Camera, and
/// Photo alongside `ColorInfoCard`'s RAL-starter-set match.
struct CatalogMatchCard: View {
    let match: NearestCatalogMatch
    /// When true, the color name/brand code/hex each give a brief free
    /// preview and then hide behind their own separate "Unlock" pill for
    /// non-subscribers — used on the live camera/gallery capture cards, not
    /// on Converter. The catalog badge (e.g. "RAL") always stays visible
    /// regardless.
    var locksWhenFree: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRevealed = true
    @State private var showsPaywall = false

    private var isLocked: Bool { locksWhenFree && !isRevealed && !SubscriptionStore.shared.isSubscribed }

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
                    .foregroundStyle(Color.appAccent)
                nameRow
                codeRow
                hexRow
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .task {
            // Fires once per card identity (i.e. once per time this screen
            // is opened), not per sampled color — the camera/gallery
            // re-samples continuously, so keying this to the color would
            // mean a steady scene keeps re-arming the preview indefinitely
            // and a shaky one keeps it locked. One teaser window per visit,
            // covering everything sampled afterward, avoids both.
            guard locksWhenFree else { return }
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                isRevealed = false
            }
        }
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private var nameRow: some View {
        if isLocked {
            UnlockPill(action: { showsPaywall = true }, isCompact: true)
                .padding(.top, 2)
        } else {
            Text(match.name)
                .font(.subheadline)
                .fontWeight(.bold)
        }
    }

    @ViewBuilder
    private var codeRow: some View {
        if isLocked {
            UnlockPill(action: { showsPaywall = true }, isCompact: true)
        } else {
            Text(match.code)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var hexRow: some View {
        if isLocked {
            UnlockPill(action: { showsPaywall = true }, isCompact: true)
        } else {
            Text("Hex: \(match.hex)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    CatalogMatchCard(match: NearestCatalogMatch(catalog: .pantone, name: "Signal Blue", code: "Pantone 042", hex: "#1E3F66"))
        .padding()
}
