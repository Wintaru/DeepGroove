import UIKit

enum AddRecordSource {
    case photo(UIImage)
    case barcode(String)
    case text(artist: String, albumTitle: String)
    case manual
}

final class AddRecordRequest: RequestBase {
    let chosenResult: DiscogsSearchResult?
    let identification: AIIdentification?
    let userPhoto: UIImage?
    let artworkPreference: ArtworkSource
    let condition: RecordCondition
    let notes: String?
    let artistOverride: String?
    let albumTitleOverride: String?
    let yearOverride: Int?
    let labelOverride: String?

    init(
        chosenResult: DiscogsSearchResult? = nil,
        identification: AIIdentification? = nil,
        userPhoto: UIImage? = nil,
        artworkPreference: ArtworkSource = .downloaded,
        condition: RecordCondition = .veryGoodPlus,
        notes: String? = nil,
        artistOverride: String? = nil,
        albumTitleOverride: String? = nil,
        yearOverride: Int? = nil,
        labelOverride: String? = nil
    ) {
        self.chosenResult = chosenResult
        self.identification = identification
        self.userPhoto = userPhoto
        self.artworkPreference = artworkPreference
        self.condition = condition
        self.notes = notes
        self.artistOverride = artistOverride
        self.albumTitleOverride = albumTitleOverride
        self.yearOverride = yearOverride
        self.labelOverride = labelOverride
        super.init()
    }
}
