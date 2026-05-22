import Foundation

final class LoadDiscogsMasterResponse: ResponseBase, @unchecked Sendable {
    let mainReleaseId: Int?

    init(correlationId: UUID, mainReleaseId: Int) {
        self.mainReleaseId = mainReleaseId
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.mainReleaseId = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
