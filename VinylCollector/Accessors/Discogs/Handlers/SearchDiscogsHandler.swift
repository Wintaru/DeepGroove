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
            var components = URLComponents(string: "https://api.discogs.com/database/search")!
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
                headers: ["User-Agent": "VinylCollector/1.0"]
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

// MARK: - Private API response types

private struct DiscogsSearchAPIResponse: Decodable {
    let results: [DiscogsSearchAPIResult]
}

private struct DiscogsSearchAPIResult: Decodable {
    let id: Int
    let title: String
    let year: String?
    let label: [String]?
    let catno: String?
    let genre: [String]?
    let style: [String]?
    let country: String?
    let thumb: String?
    let coverImage: String?
    let barcode: [String]?

    enum CodingKeys: String, CodingKey {
        case id, title, year, label, catno, genre, style, country, thumb, barcode
        case coverImage = "cover_image"
    }

    func toSearchResult() -> DiscogsSearchResult {
        DiscogsSearchResult(
            id: id,
            title: title,
            year: year,
            labels: label ?? [],
            catalogNumber: catno,
            genres: genre ?? [],
            styles: style ?? [],
            country: country,
            thumbURL: thumb,
            coverImageURL: coverImage,
            barcodes: barcode ?? []
        )
    }
}
