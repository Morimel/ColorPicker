import SwiftUI

/// Owns Home's navigation path and translates incoming deep links into a
/// concrete path, so a cold or warm launch lands directly on the linked screen.
@Observable
final class HomeViewModel {
    var path = NavigationPath()
    var showsPaywall = false

    /// Pushes `destination` if it's unrestricted (camera/photo) or the user
    /// still has their one free visit to it (converter/palettes/saved);
    /// otherwise surfaces the paywall instead of navigating.
    func navigate(to destination: HomeDestination) {
        if let gate = destination.gatedScreen, !SubscriptionStore.shared.canVisit(gate) {
            showsPaywall = true
            return
        }
        path.append(destination)
    }

    /// Applies `url` as a deep link by resetting and re-populating the
    /// navigation path. Returns whether the URL was a recognized deep link
    /// (so the caller knows whether to clear it).
    @discardableResult
    func handle(url: URL?) -> Bool {
        guard let url, let route = ColorDeepLink(url: url) else { return false }
        path = NavigationPath()
        switch route {
        case .color(let id): path.append(id)
        case .saved: path.append(HomeDestination.saved)
        }
        return true
    }
}
