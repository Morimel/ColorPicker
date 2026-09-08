import SwiftUI

/// Shared motion keeps touch feedback and entrances consistent across screens.
enum AppMotion {
    static let spring = Animation.spring(response: 0.36, dampingFraction: 0.82)
}

struct SoftPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(reduceMotion ? nil : AppMotion.spring, value: configuration.isPressed)
    }
}

private struct EntranceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appeared || reduceMotion ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 16)
            .animation(reduceMotion ? nil : AppMotion.spring.delay(delay), value: appeared)
            .onAppear { appeared = true }
    }
}

extension View {
    func softEntrance(delay: Double = 0) -> some View {
        modifier(EntranceModifier(delay: delay))
    }
}
