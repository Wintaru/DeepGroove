import Foundation

final class SearchITunesResponse: ResponseBase, @unchecked Sendable {
    let url: String?

    init(correlationId: UUID, url: String?) {
        self.url = url
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.url = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
