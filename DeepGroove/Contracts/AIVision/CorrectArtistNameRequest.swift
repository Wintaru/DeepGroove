import Foundation

final class CorrectArtistNameRequest: RequestBase, @unchecked Sendable {
    let input: String
    let apiKey: String

    init(input: String, apiKey: String) {
        self.input = input
        self.apiKey = apiKey
        super.init()
    }
}
