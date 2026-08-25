import Foundation

// Resolves a chosen search result to its full release details, in one place shared by
// every caller that turns a DiscogsSearchResult into a DiscogsRelease. Master results
// resolve to their canonical release via the master endpoint first.
final class ResolveDiscogsReleaseHandler: IHandler {
    private let discogsAccessor: IDiscogsAccessor

    init(discogsAccessor: IDiscogsAccessor) {
        self.discogsAccessor = discogsAccessor
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? ResolveDiscogsReleaseRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let releaseId: Int
        if req.chosenResult.isMaster {
            let masterResponse = await discogsAccessor.load(
                LoadDiscogsMasterRequest(masterId: req.chosenResult.id, token: req.token)
            )
            releaseId = (masterResponse as? LoadDiscogsMasterResponse)?.mainReleaseId ?? req.chosenResult.id
        } else {
            releaseId = req.chosenResult.id
        }

        return await discogsAccessor.load(LoadDiscogsReleaseRequest(releaseId: releaseId, token: req.token))
    }
}
