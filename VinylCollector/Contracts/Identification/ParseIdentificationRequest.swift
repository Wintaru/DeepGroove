import Foundation

final class ParseIdentificationRequest: RequestBase {
    let rawJSON: String

    init(rawJSON: String) {
        self.rawJSON = rawJSON
        super.init()
    }
}
