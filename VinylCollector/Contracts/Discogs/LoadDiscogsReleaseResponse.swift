import Foundation

struct DiscogsRelease: Sendable {
    let id: Int
    let title: String
    let artists: [String]
    let year: Int?
    let labels: [DiscogsLabel]
    let genres: [String]
    let styles: [String]
    let country: String?
    let primaryImageURL: String?
    let secondaryImageURLs: [String]
    let tracklist: [DiscogsTrack]
    let lowestPrice: Double?
    let numForSale: Int?
}

struct DiscogsLabel: Sendable {
    let name: String
    let catalogNumber: String?
}

struct DiscogsTrack: Sendable {
    let position: String
    let title: String
    let duration: String?
}

final class LoadDiscogsReleaseResponse: ResponseBase, @unchecked Sendable {
    let release: DiscogsRelease?

    init(correlationId: UUID, release: DiscogsRelease) {
        self.release = release
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.release = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
