import UIKit

final class SearchRecordResponse: ResponseBase, @unchecked Sendable {
    let candidates: [DiscogsSearchResult]
    let identification: AIIdentification?
    let userPhoto: UIImage?
    let currentPage: Int
    let totalPages: Int
    let correctedArtist: String?

    init(correlationId: UUID, candidates: [DiscogsSearchResult],
         identification: AIIdentification? = nil, userPhoto: UIImage? = nil,
         currentPage: Int = 1, totalPages: Int = 1, correctedArtist: String? = nil) {
        self.candidates = candidates
        self.identification = identification
        self.userPhoto = userPhoto
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.correctedArtist = correctedArtist
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.candidates = []
        self.identification = nil
        self.userPhoto = nil
        self.currentPage = 1
        self.totalPages = 1
        self.correctedArtist = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
