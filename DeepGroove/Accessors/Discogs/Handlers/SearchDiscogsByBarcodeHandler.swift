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
            let (results, totalPages) = try await performDiscogsSearch(
                queryItems: [
                    URLQueryItem(name: "barcode", value: req.barcode),
                    URLQueryItem(name: "type", value: "release")
                ],
                token: req.token,
                page: req.page,
                networkUtility: networkUtility
            )
            return SearchDiscogsResponse(correlationId: req.correlationId, results: results,
                                          totalPages: totalPages)
        } catch {
            return SearchDiscogsResponse(correlationId: req.correlationId,
                                          errorMessage: error.localizedDescription)
        }
    }
}
