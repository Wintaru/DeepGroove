import Foundation

struct DiscogsSearchAPIResponse: Decodable {
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
