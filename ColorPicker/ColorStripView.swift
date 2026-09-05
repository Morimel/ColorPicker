//
//  ColorStripView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 5/9/26.
//

import SwiftUI

/// A single rounded-rect bar split into equal-width segments, one per color.
/// Used anywhere a palette needs a compact visual summary: the photo
/// picker's dominant-colors strip, the palette detail header, palette rows
/// in "Палитры" and "Сохраненные".
struct ColorStripView: View {
    let colors: [RGBColor]
    var height: CGFloat = 56
    var cornerRadius: CGFloat = 14

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Color(hex: color.hexString)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#Preview {
    ColorStripView(colors: [
        RGBColor(r: 229, g: 190, b: 1),
        RGBColor(r: 205, g: 164, b: 52),
        RGBColor(r: 183, g: 217, b: 177),
        RGBColor(r: 87, g: 166, b: 57),
    ])
    .padding()
}
