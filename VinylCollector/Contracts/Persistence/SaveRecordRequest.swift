import Foundation

struct RecordCreationData: Sendable {
    let artist: String
    let albumTitle: String
    let year: Int?
    let label: String?
    let catalogNumber: String?
    let genres: [String]
    let styles: [String]
    let country: String?
    let discogsId: Int?
    let notes: String?
    let condition: RecordCondition
    let artworkSource: ArtworkSource
    let artworkURL: String?
    let estimatedValue: Double?
}

final class SaveRecordRequest: RequestBase, @unchecked Sendable {
    let data: RecordCreationData

    init(data: RecordCreationData) {
        self.data = data
        super.init()
    }
}
