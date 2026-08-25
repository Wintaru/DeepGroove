import Foundation

final class RematchRecordRequest: RequestBase, @unchecked Sendable {
    let recordId: UUID
    let chosenResult: DiscogsSearchResult

    init(recordId: UUID, chosenResult: DiscogsSearchResult) {
        self.recordId = recordId
        self.chosenResult = chosenResult
        super.init()
    }
}
