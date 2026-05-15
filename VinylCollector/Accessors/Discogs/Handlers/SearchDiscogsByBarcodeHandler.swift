import Foundation

final class SearchDiscogsByBarcodeHandler: IHandler {
    private let networkUtility: NetworkUtility

    init(networkUtility: NetworkUtility) {
        self.networkUtility = networkUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? SearchDiscogsByBarcodeRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            var components = URLComponents(string: DiscogsAPI.searchURL)!
            components.queryItems = [
                URLQueryItem(name: "barcode", value: req.barcode),
                URLQueryItem(name: "type", value: "release")
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
            return SearchDiscogsByBarcodeResponse(correlationId: req.correlationId, results: results)
        } catch {
            return SearchDiscogsByBarcodeResponse(correlationId: req.correlationId,
                                                   errorMessage: error.localizedDescription)
        }
    }
}
