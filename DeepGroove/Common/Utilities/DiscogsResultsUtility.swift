import Foundation

final class DiscogsResultsUtility: Sendable {
    // Appends a freshly-fetched page of results to what's already on screen, capped so an
    // eager "Load More" tap can't grow the picker list without bound.
    func appendingPage(to existing: [DiscogsSearchResult], newResults: [DiscogsSearchResult],
                       maxCandidates: Int = 40) -> [DiscogsSearchResult] {
        Array((existing + newResults).prefix(maxCandidates))
    }
}
