import Foundation

final class ResolveDiscogsReleaseRequest: RequestBase, @unchecked Sendable {
    let chosenResult: DiscogsSearchResult
    let token: String?

    init(chosenResult: DiscogsSearchResult, token: String?) {
        self.chosenResult = chosenResult
        self.token = token
        super.init()
    }
}
