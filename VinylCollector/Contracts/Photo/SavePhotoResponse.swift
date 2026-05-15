import Foundation

final class SavePhotoResponse: ResponseBase, @unchecked Sendable {
    let photo: RecordPhoto?

    init(correlationId: UUID, photo: RecordPhoto) {
        self.photo = photo
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.photo = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
