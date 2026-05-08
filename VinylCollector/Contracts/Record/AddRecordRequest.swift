import UIKit

enum AddRecordSource {
    case photo(UIImage)
    case barcode(String)
    case manual
}

final class AddRecordRequest: RequestBase {
    let source: AddRecordSource
    let artworkPreference: ArtworkSource
    let condition: RecordCondition
    let notes: String?
    // Optional overrides applied after identification (user-supplied corrections)
    let artistOverride: String?
    let albumTitleOverride: String?
    let yearOverride: Int?
    let labelOverride: String?

    init(
        source: AddRecordSource,
        artworkPreference: ArtworkSource = .downloaded,
        condition: RecordCondition = .veryGoodPlus,
        notes: String? = nil,
        artistOverride: String? = nil,
        albumTitleOverride: String? = nil,
        yearOverride: Int? = nil,
        labelOverride: String? = nil
    ) {
        self.source = source
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
