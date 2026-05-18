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
            var queryItems: [URLQueryItem] = [URLQueryItem(name: "type", value: "release")]
            if let q = req.query          { queryItems.append(.init(name: "q",             value: q)) }
            if let a = req.artist         { queryItems.append(.init(name: "artist",         value: a)) }
            if let t = req.releaseTitle   { queryItems.append(.init(name: "release_title",  value: t)) }
            if let s = req.sort           { queryItems.append(.init(name: "sort",           value: s)) }
            if let o = req.sortOrder      { queryItems.append(.init(name: "sort_order",     value: o)) }

            let (results, totalPages) = try await performDiscogsSearch(
                queryItems: queryItems,
                token: req.token,
                page: req.page,
                perPage: req.perPage,
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
