//
//  ToastView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 4/9/26.
//

import SwiftUI

// MARK: - ToastView

struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.black.opacity(0.85)))
    }
}

// MARK: - Saved toast modifier

/// Shows a brief bottom toast whenever `isPresented` becomes `true`, then
/// automatically flips it back to `false` after a couple of seconds.
private struct SavedToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let text: String

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isPresented {
                    ToastView(text: text)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: isPresented)
            .onChange(of: isPresented) { _, isShown in
                guard isShown else { return }
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    isPresented = false
                }
            }
    }
}

extension View {
    func savedToast(isPresented: Binding<Bool>, text: String) -> some View {
        modifier(SavedToastModifier(isPresented: isPresented, text: text))
    }
}
