import Foundation

final class MergeMetadataRequest: RequestBase {
    let identification: AIIdentification?
    let discogsRelease: DiscogsRelease?
    let artworkPreference: ArtworkSource
    let conditionOverride: RecordCondition
    let artistOverride: String?
    let albumTitleOverride: String?
    let yearOverride: Int?
    let labelOverride: String?
    let notes: String?

    init(
        identification: AIIdentification?,
        discogsRelease: DiscogsRelease?,
        artworkPreference: ArtworkSource,
        conditionOverride: RecordCondition,
        artistOverride: String? = nil,
        albumTitleOverride: String? = nil,
        yearOverride: Int? = nil,
        labelOverride: String? = nil,
        notes: String? = nil
    ) {
        self.identification = identification
        self.discogsRelease = discogsRelease
        self.artworkPreference = artworkPreference
        self.conditionOverride = conditionOverride
        self.artistOverride = artistOverride
        self.albumTitleOverride = albumTitleOverride
        self.yearOverride = yearOverride
        self.labelOverride = labelOverride
        self.notes = notes
        super.init()
    }
}
