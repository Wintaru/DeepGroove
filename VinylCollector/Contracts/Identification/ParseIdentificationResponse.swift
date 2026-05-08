import Foundation

final class ParseIdentificationResponse: ResponseBase {
    let identification: AIIdentification?

    init(correlationId: UUID, identification: AIIdentification) {
        self.identification = identification
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.identification = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
