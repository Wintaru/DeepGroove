import UIKit

final class SearchRecordResponse: ResponseBase {
    let candidates: [DiscogsSearchResult]
    let identification: AIIdentification?
    let userPhoto: UIImage?

    init(correlationId: UUID, candidates: [DiscogsSearchResult],
         identification: AIIdentification? = nil, userPhoto: UIImage? = nil) {
        self.candidates = candidates
        self.identification = identification
        self.userPhoto = userPhoto
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.candidates = []
        self.identification = nil
        self.userPhoto = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
