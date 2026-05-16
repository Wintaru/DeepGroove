import UIKit

final class SearchRecordResponse: ResponseBase, @unchecked Sendable {
    let candidates: [DiscogsSearchResult]
    let identification: AIIdentification?
    let userPhoto: UIImage?
    let currentPage: Int
    let totalPages: Int

    init(correlationId: UUID, candidates: [DiscogsSearchResult],
         identification: AIIdentification? = nil, userPhoto: UIImage? = nil,
         currentPage: Int = 1, totalPages: Int = 1) {
        self.candidates = candidates
        self.identification = identification
        self.userPhoto = userPhoto
        self.currentPage = currentPage
        self.totalPages = totalPages
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.candidates = []
        self.identification = nil
        self.userPhoto = nil
        self.currentPage = 1
        self.totalPages = 1
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
