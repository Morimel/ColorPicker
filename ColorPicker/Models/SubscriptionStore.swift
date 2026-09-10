import Foundation

/// A top-level screen that's free to open once and then paywalled — as
/// opposed to camera/photo, which stay open but lock the sampled values
/// themselves (see `ColorInfoCard.locksWhenFree`).
enum GatedScreen: String, CaseIterable {
    case converter, palettes, saved

    fileprivate var visitedDefaultsKey: String { "hasVisited_\(rawValue)" }
}

/// Single source of truth for whether the user currently has an active
/// subscription. No App Store product is wired up yet (see
/// `PaywallViewModel`), so this always reports `false` for now — once real
/// purchases/receipt validation land, only this property needs to change.
@Observable
final class SubscriptionStore {
    static let shared = SubscriptionStore()

    private(set) var isSubscribed: Bool = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Whether `screen` may be opened right now: subscribers always may;
    /// everyone else gets exactly one free visit, tracked permanently (not
    /// just for the session) so relaunching the app doesn't reset it. The
    /// first call for a given screen both answers `true` and consumes that
    /// free visit, so call this once per navigation attempt, not per render.
    func canVisit(_ screen: GatedScreen) -> Bool {
        guard !isSubscribed else { return true }
        guard !defaults.bool(forKey: screen.visitedDefaultsKey) else { return false }
        defaults.set(true, forKey: screen.visitedDefaultsKey)
        return true
    }
}
