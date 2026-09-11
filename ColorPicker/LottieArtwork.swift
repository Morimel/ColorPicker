import Lottie
import SwiftUI

/// Bundled artwork works offline. Only visible, active screens play animations.
struct LottieArtwork: View {
    enum Asset: String {
        case camera = "home-camera"
        case gallery = "home-gallery"
        case converter = "home-converter"
        case palette = "palette-fan"
        case scan = "color-scan"
        case search = "color-search"
        case success = "save-success"

        var fallback: String {
            switch self {
            case .camera: "camera.fill"
            case .gallery: "photo.on.rectangle"
            case .converter: "arrow.left.arrow.right"
            case .palette: "swatchpalette.fill"
            case .scan: "viewfinder"
            case .search: "magnifyingglass"
            case .success: "checkmark.circle.fill"
            }
        }
    }

    let asset: Asset
    var isActive = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = false

    var body: some View {
        Group {
            if let animation = LottieAnimation.named(asset.rawValue) {
                LottieView(animation: animation)
                    .playbackMode(reduceMotion
                        ? .paused(at: .progress(1))
                        : isActive && isVisible && scenePhase == .active
                            ? .playing(.fromProgress(0, toProgress: 1, loopMode: asset == .success ? .playOnce : .loop))
                            : .paused(at: .progress(1)))
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: asset.fallback)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.appAccent)
                    .padding(12)
            }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
