import Foundation

func performDiscogsSearch(
    queryItems: [URLQueryItem],
    token: String?,
    page: Int = 1,
    networkUtility: NetworkUtility
) async throws -> (results: [DiscogsSearchResult], totalPages: Int) {
    var components = URLComponents(string: DiscogsAPI.searchURL)!
    components.queryItems = queryItems
    components.queryItems?.append(URLQueryItem(name: "per_page", value: "25"))
    components.queryItems?.append(URLQueryItem(name: "page", value: String(page)))
    if let token {
        components.queryItems?.append(URLQueryItem(name: "token", value: token))
    }
    let data = try await networkUtility.get(url: components.url!, headers: DiscogsAPI.userAgentHeaders)
    let decoded = try JSONDecoder().decode(DiscogsSearchAPIResponse.self, from: data)
    return (decoded.results.map { $0.toSearchResult() }, decoded.pagination.pages)
}

fileprivate struct DiscogsPagination: Decodable {
    let pages: Int
}

fileprivate struct DiscogsSearchAPIResponse: Decodable {
    let pagination: DiscogsPagination
    let results: [DiscogsSearchAPIResult]
}

struct DiscogsSearchAPIResult: Decodable {
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
