import Foundation

class RequestBase: @unchecked Sendable {
    let correlationId: UUID
    let timestamp: Date

    init(correlationId: UUID = UUID(), timestamp: Date = Date()) {
        self.correlationId = correlationId
        self.timestamp = timestamp
    }
}
