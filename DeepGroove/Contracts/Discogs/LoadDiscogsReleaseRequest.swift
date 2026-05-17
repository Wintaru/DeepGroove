import Foundation

final class LoadDiscogsReleaseRequest: RequestBase, @unchecked Sendable {
    let releaseId: Int
    let token: String?

    init(releaseId: Int, token: String? = nil) {
        self.releaseId = releaseId
        self.token = token
        super.init()
    }
}
