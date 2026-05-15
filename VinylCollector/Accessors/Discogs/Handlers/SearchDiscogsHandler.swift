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
            var components = URLComponents(string: DiscogsAPI.searchURL)!
            components.queryItems = [
                URLQueryItem(name: "q", value: req.query),
                URLQueryItem(name: "type", value: "release"),
                URLQueryItem(name: "per_page", value: "10")
            ]
            if let token = req.token {
                components.queryItems?.append(URLQueryItem(name: "token", value: token))
            }
            let data = try await networkUtility.get(
                url: components.url!,
                headers: DiscogsAPI.userAgentHeaders
            )
            let decoded = try JSONDecoder().decode(DiscogsSearchAPIResponse.self, from: data)
            let results = decoded.results.map { $0.toSearchResult() }
            return SearchDiscogsResponse(correlationId: req.correlationId, results: results)
        } catch {
            return SearchDiscogsResponse(correlationId: req.correlationId,
                                         errorMessage: error.localizedDescription)
        }
    }
}
