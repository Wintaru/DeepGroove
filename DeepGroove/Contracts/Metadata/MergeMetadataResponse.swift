import Foundation

struct RecordCandidate: Sendable {
    let artist: String
    let albumTitle: String
    let year: Int?
    let label: String?
    let catalogNumber: String?
    let genres: [String]
    let styles: [String]
    let country: String?
    let discogsId: Int?
    let artworkURL: String?
    let estimatedValue: Double?
    let condition: RecordCondition
    let artworkSource: ArtworkSource
    let notes: String?
    let appleMusicURL: String?

    init(
        artist: String,
        albumTitle: String,
        year: Int? = nil,
        label: String? = nil,
        catalogNumber: String? = nil,
        genres: [String] = [],
        styles: [String] = [],
        country: String? = nil,
        discogsId: Int? = nil,
        artworkURL: String? = nil,
        estimatedValue: Double? = nil,
        condition: RecordCondition = .veryGoodPlus,
        artworkSource: ArtworkSource = .downloaded,
        notes: String? = nil,
        appleMusicURL: String? = nil
    ) {
        self.artist = artist
        self.albumTitle = albumTitle
        self.year = year
        self.label = label
        self.catalogNumber = catalogNumber
        self.genres = genres
        self.styles = styles
        self.country = country
        self.discogsId = discogsId
        self.artworkURL = artworkURL
        self.estimatedValue = estimatedValue
        self.condition = condition
        self.artworkSource = artworkSource
        self.notes = notes
        self.appleMusicURL = appleMusicURL
    }
}

final class MergeMetadataResponse: ResponseBase, @unchecked Sendable {
    let candidate: RecordCandidate?

    init(correlationId: UUID, candidate: RecordCandidate) {
        self.candidate = candidate
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.candidate = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
