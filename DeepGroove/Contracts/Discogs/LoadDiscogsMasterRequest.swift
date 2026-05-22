import Foundation

final class LoadDiscogsMasterRequest: RequestBase, @unchecked Sendable {
    let masterId: Int
    let token: String?

    init(masterId: Int, token: String? = nil) {
        self.masterId = masterId
        self.token = token
        super.init()
    }
}
