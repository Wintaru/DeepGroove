import Foundation

class ResponseBase {
    let correlationId: UUID
    let success: Bool
    let errorMessage: String?

    init(correlationId: UUID, success: Bool, errorMessage: String? = nil) {
        self.correlationId = correlationId
        self.success = success
        self.errorMessage = errorMessage
    }
}

final class UnhandledRequestResponse: ResponseBase {
    let requestType: String

    init(correlationId: UUID, requestType: String) {
        self.requestType = requestType
        super.init(
            correlationId: correlationId,
            success: false,
            errorMessage: "No handler registered for request type: \(requestType)"
        )
    }
}
