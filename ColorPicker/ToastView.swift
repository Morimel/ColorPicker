//
//  ToastView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 4/9/26.
//

import SwiftUI

// MARK: - ToastView

struct ToastView: View {
    let text: LocalizedStringKey

    var body: some View {
        HStack(spacing: 10) {
            LottieArtwork(asset: .success)
                .frame(width: 30, height: 30)
            Text(text)
        }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isPresented: Bool
    let text: LocalizedStringKey

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isPresented {
                    ToastView(text: text)
                        .padding(.bottom, 24)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : AppMotion.spring, value: isPresented)
            .task(id: isPresented) {
                guard isPresented else { return }
                do {
                    try await Task.sleep(for: .seconds(2))
                    isPresented = false
                } catch {
                    // A dismissed toast or disappearing screen cancels its timer.
                }
            }
    }
}

extension View {
    func savedToast(isPresented: Binding<Bool>, text: LocalizedStringKey) -> some View {
        modifier(SavedToastModifier(isPresented: isPresented, text: text))
    }
}
