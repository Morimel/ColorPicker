//
//  ColorInfoCard.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import SwiftUI
import UIKit

/// Reusable row that presents a sampled/saved color: swatch on the left,
/// RAL name + hex/cmyk/rgb detail stack on the right. Used in the camera
/// result card, the photo picker's sampled-colors list, and the future
/// Saved/Palettes screens.
struct ColorInfoCard: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let swatch: Color
    let ralName: String
    let ralCode: String
    let hex: String
    let cmyk: String
    let rgb: String

    var showsBorder: Bool = false
    var trailingAction: (() -> Void)? = nil
    var trailingIcon: String = "plus.circle.fill"
    var onCopied: (() -> Void)? = nil
    /// When true, the name/code and hex/cmyk/rgb values give a brief free
    /// preview and then hide behind "Unlock" pills for non-subscribers —
    /// used on the live camera/gallery capture cards, not on saved/browsing
    /// screens where the same card is reused.
    var locksWhenFree: Bool = false

    @State private var isRevealed = true
    @State private var showsPaywall = false

    private var isLocked: Bool { locksWhenFree && !isRevealed && !SubscriptionStore.shared.isSubscribed }

    init(swatch: Color, ralName: String, ralCode: String, hex: String, cmyk: String, rgb: String, showsBorder: Bool = false, trailingAction: (() -> Void)? = nil, trailingIcon: String = "plus.circle.fill", onCopied: (() -> Void)? = nil, locksWhenFree: Bool = false) {
        self.swatch = swatch
        self.ralName = ralName
        self.ralCode = ralCode
        self.hex = hex
        self.cmyk = cmyk
        self.rgb = rgb
        self.showsBorder = showsBorder
        self.trailingAction = trailingAction
        self.trailingIcon = trailingIcon
        self.onCopied = onCopied
        self.locksWhenFree = locksWhenFree
    }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(swatch)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: hex)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                if isLocked {
                    UnlockPill(action: { showsPaywall = true })
                        .padding(.bottom, 3)
                } else {
                    Text(ralCode)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text(ralName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                detailRow(label: "Hex:", value: hex)
                detailRow(label: "CMYK:", value: cmyk)
                detailRow(label: "RGB:", value: rgb)
            }

            Spacer(minLength: 0)

            if let onCopied {
                Menu {
                    Button("HEX: \(hex)") { copy(hex, onCopied: onCopied) }
                    Button("RGB: \(rgb)") { copy(rgb, onCopied: onCopied) }
                    Button("CMYK: \(cmyk)") { copy(cmyk, onCopied: onCopied) }
                } label: {
                    Label("Копировать", systemImage: "doc.on.doc")
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color.appAccent)
                .accessibilityLabel("Копировать цвет \(hex)")
            }

            if let trailingAction {
                Button(action: trailingAction) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 26))
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(SoftPressButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay {
            if showsBorder {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(.separator), lineWidth: 0.5)
            }
        }
        .task {
            // Fires once per card identity (i.e. once per time this screen
            // is opened), not per sampled color — the camera re-samples
            // several times a second, so keying this to the color would
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

    private func detailRow(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if isLocked {
                UnlockPill(action: { showsPaywall = true }, isCompact: true)
            } else {
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func copy(_ value: String, onCopied: () -> Void) {
        UIPasteboard.general.string = value
        onCopied()
    }
}

// MARK: - UnlockPill

/// The "Unlock" pill that stands in for a locked name/code or hex/cmyk/rgb
/// value on the live capture cards. `isCompact` shrinks it to sit inline next
/// to a "Hex:"/"CMYK:"/"RGB:" label instead of spanning the row. Uses the
/// same purple as the paywall's CTA/"best value" badge so a crown+Unlock
/// pill reads as the same "premium" affordance everywhere it appears.
private struct UnlockPill: View {
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

extension ColorInfoCard {
    init(rgb: RGBColor, ral: RALColor, showsBorder: Bool = false, trailingAction: (() -> Void)? = nil, trailingIcon: String = "plus.circle.fill", onCopied: (() -> Void)? = nil, locksWhenFree: Bool = false) {
        self.init(
            swatch: Color(hex: rgb.hexString),
            ralName: ral.localizedName,
            ralCode: ral.code,
            hex: rgb.hexString,
            cmyk: rgb.cmykString,
            rgb: rgb.rgbString,
            showsBorder: showsBorder,
            trailingAction: trailingAction,
            trailingIcon: trailingIcon,
            onCopied: onCopied,
            locksWhenFree: locksWhenFree
        )
    }
}

#Preview {
    ColorInfoCard(
        rgb: RGBColor(r: 204, g: 197, b: 143),
        ral: RALPalette.colors[0],
        trailingAction: {}
    )
    .padding()
}
