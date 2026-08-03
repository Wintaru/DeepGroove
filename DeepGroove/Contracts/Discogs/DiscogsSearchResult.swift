import Foundation

struct DiscogsSearchResult: Sendable, Hashable, Codable {
    let id: Int
    let masterId: Int?
    let isMaster: Bool
    let title: String
    let year: String?
    let labels: [String]
    let catalogNumber: String?
    let genres: [String]
    let styles: [String]
    let country: String?
    let thumbURL: String?
    let coverImageURL: String?
    let barcodes: [String]
}
