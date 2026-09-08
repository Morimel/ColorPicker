import SwiftUI

/// Owns Home's navigation path and translates incoming deep links into a
/// concrete path, so a cold or warm launch lands directly on the linked screen.
@Observable
final class HomeViewModel {
    var path = NavigationPath()

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
