import Foundation

final class SaveRecordRequest: RequestBase, @unchecked Sendable {
    let candidate: RecordCandidate

    init(candidate: RecordCandidate) {
        self.candidate = candidate
        super.init()
    }
}
