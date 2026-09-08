import SwiftUI

/// Continues straight on from the static system Launch Screen (same white
/// background, same logo, same size/position — see `LaunchScreen.storyboard`)
/// and animates the logo in, since the real launch screen can't run any code
/// or animate itself. Sits on top of the app's real content and fades away
/// once the animation has played.
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Hardcoded white, matching the storyboard exactly — using
            // `Color(.systemBackground)` would flash to black in dark mode
            // right as the system launch screen hands off to this view.
            Color.white
                .ignoresSafeArea()

            Image("launchAndLogoImage")
                .resizable()
                .scaledToFit()
                .frame(width: 174, height: 192)
                .opacity(isAnimating ? 1 : 0)
        }
        .onAppear {
            guard !reduceMotion else {
                isAnimating = true
                return
            }
            withAnimation(.easeIn(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}
