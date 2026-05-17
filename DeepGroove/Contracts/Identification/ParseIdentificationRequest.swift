import Foundation

final class ParseIdentificationRequest: RequestBase, @unchecked Sendable {
    let rawJSON: String

    init(rawJSON: String) {
        self.rawJSON = rawJSON
        super.init()
    }
}
