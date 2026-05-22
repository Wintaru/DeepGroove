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
            var queryItems: [URLQueryItem] = [URLQueryItem(name: "type", value: req.releaseType)]
            if let q = req.query          { queryItems.append(.init(name: "q",             value: q)) }
            if let a = req.artist         { queryItems.append(.init(name: "artist",         value: a)) }
            if let t = req.releaseTitle   { queryItems.append(.init(name: "release_title",  value: t)) }
            if let s = req.sort           { queryItems.append(.init(name: "sort",           value: s)) }
            if let o = req.sortOrder      { queryItems.append(.init(name: "sort_order",     value: o)) }
            if let c = req.country        { queryItems.append(.init(name: "country",        value: c)) }
            if let f = req.format         { queryItems.append(.init(name: "format",         value: f)) }

            let (results, totalPages) = try await performDiscogsSearch(
                queryItems: queryItems,
                token: req.token,
                page: req.page,
                perPage: req.perPage,
                networkUtility: networkUtility
            )
            #if DEBUG
            let paramString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            print("[Discogs Search] \(paramString) → \(results.count) results")
            results.prefix(5).forEach { print("  [\($0.isMaster ? "master" : "release")] \($0.title)") }
            #endif
            return SearchDiscogsResponse(correlationId: req.correlationId, results: results,
                                         totalPages: totalPages)
        } catch {
            return SearchDiscogsResponse(correlationId: req.correlationId,
                                         errorMessage: error.localizedDescription)
        }
    }
}
