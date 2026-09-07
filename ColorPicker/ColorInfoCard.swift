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

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(swatch)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(ralCode)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(ralName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Hex: \(hex)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("CMYK: \(cmyk)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("RGB: \(rgb)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                .foregroundStyle(Color.tealAccent)
                .accessibilityLabel("Копировать цвет \(hex)")
            }

            if let trailingAction {
                Button(action: trailingAction) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 26))
                        .foregroundStyle(Color.tealAccent)
                }
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
    }

    private func copy(_ value: String, onCopied: () -> Void) {
        UIPasteboard.general.string = value
        onCopied()
    }
}

extension ColorInfoCard {
    init(rgb: RGBColor, ral: RALColor, showsBorder: Bool = false, trailingAction: (() -> Void)? = nil, trailingIcon: String = "plus.circle.fill", onCopied: (() -> Void)? = nil) {
        self.init(
            swatch: Color(hex: rgb.hexString),
            ralName: ral.nameRu,
            ralCode: ral.code,
            hex: rgb.hexString,
            cmyk: rgb.cmykString,
            rgb: rgb.rgbString,
            showsBorder: showsBorder,
            trailingAction: trailingAction,
            trailingIcon: trailingIcon,
            onCopied: onCopied
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
