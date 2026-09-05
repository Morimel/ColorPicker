//
//  CameraOverlayButton.swift
//  ColorPicker
//
//  Created by Isa Melsov on 5/9/26.
//

import SwiftUI

/// The circular semi-transparent icon used for controls overlaid directly on
/// a camera/photo preview (flash toggle, gallery shortcut, image picker).
/// Label-only — wrap it in a `Button` or `NavigationLink` depending on what
/// the control needs to do.
struct CameraOverlayButton: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(Circle().fill(.black.opacity(0.5)))
    }
}

#Preview {
    ZStack {
        Color.gray
        CameraOverlayButton(systemImage: "bolt.slash.fill")
    }
    .frame(width: 120, height: 120)
}
