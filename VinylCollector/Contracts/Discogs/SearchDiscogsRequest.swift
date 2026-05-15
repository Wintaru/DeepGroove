import Foundation

final class SearchDiscogsRequest: RequestBase, @unchecked Sendable {
    let query: String
    let token: String?

    init(query: String, token: String? = nil) {
        self.query = query
        self.token = token
        super.init()
    }
}
