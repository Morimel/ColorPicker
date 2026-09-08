import Foundation

/// Composition root: owns the app-wide stores and the onboarding/deep-link
/// state that `ContentView` renders.
@Observable
final class RootViewModel {
    let savedColorsStore = SavedColorsStore()
    let paletteStore = PaletteStore()

    var incomingURL: URL?
    var isOnboardingVisible: Bool

    init() {
        // Note: a stored property's default value can't reference a sibling
        // property, so we read the same UserDefaults key directly here to
        // seed the initial value.
        isOnboardingVisible = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    func handleOpenURL(_ url: URL) {
        guard ColorDeepLink(url: url) != nil else { return }
        // A valid widget link goes directly to its destination on cold and warm launches.
        isOnboardingVisible = false
        incomingURL = url
    }

    var persistenceError: String? {
        get { savedColorsStore.persistenceError }
        set { savedColorsStore.persistenceError = newValue }
    }
}
