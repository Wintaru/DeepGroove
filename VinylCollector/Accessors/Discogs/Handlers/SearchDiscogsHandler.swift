import Foundation

final class SearchDiscogsHandler: IHandler {
    private let networkUtility: NetworkUtility

    init(networkUtility: NetworkUtility) {
        self.networkUtility = networkUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? SearchDiscogsRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            let results = try await performDiscogsSearch(
                queryItems: [
                    URLQueryItem(name: "q", value: req.query),
                    URLQueryItem(name: "type", value: "release"),
                    URLQueryItem(name: "per_page", value: "10")
                ],
                token: req.token,
                networkUtility: networkUtility
            )
            return SearchDiscogsResponse(correlationId: req.correlationId, results: results)
        } catch {
            return SearchDiscogsResponse(correlationId: req.correlationId,
                                         errorMessage: error.localizedDescription)
        }
    }
}
