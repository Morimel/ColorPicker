import Foundation

/// Owns which onboarding page is current and the page-sequencing logic.
@Observable
final class OnboardingViewModel {
    var currentPage: OnboardingPage = .colorScan

    /// The page to advance to, or `nil` if `currentPage` is the last one
    /// (in which case the caller should finish onboarding instead).
    func nextPage() -> OnboardingPage? {
        guard let currentIndex = OnboardingPage.allCases.firstIndex(of: currentPage) else { return nil }
        let nextIndex = OnboardingPage.allCases.index(after: currentIndex)
        guard nextIndex < OnboardingPage.allCases.endIndex else { return nil }
        return OnboardingPage.allCases[nextIndex]
    }
}
