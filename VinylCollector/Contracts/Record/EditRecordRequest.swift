import Foundation

final class EditRecordRequest: RequestBase {
    let recordId: UUID
    let artist: String?
    let albumTitle: String?
    let year: Int??
    let label: String??
    let catalogNumber: String??
    let genres: [String]?
    let styles: [String]?
    let country: String??
    let notes: String??
    let condition: RecordCondition?
    let artworkPreference: ArtworkSource?
    let discogsId: Int??

    init(
        recordId: UUID,
        artist: String? = nil,
        albumTitle: String? = nil,
        year: Int?? = nil,
        label: String?? = nil,
        catalogNumber: String?? = nil,
        genres: [String]? = nil,
        styles: [String]? = nil,
        country: String?? = nil,
        notes: String?? = nil,
        condition: RecordCondition? = nil,
        artworkPreference: ArtworkSource? = nil,
        discogsId: Int?? = nil
    ) {
        self.recordId = recordId
        self.artist = artist
        self.albumTitle = albumTitle
        self.year = year
        self.label = label
        self.catalogNumber = catalogNumber
        self.genres = genres
        self.styles = styles
        self.country = country
        self.notes = notes
        self.condition = condition
        self.artworkPreference = artworkPreference
        self.discogsId = discogsId
        super.init()
    }
}
