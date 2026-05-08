import Foundation

final class LoadDiscogsReleaseRequest: RequestBase {
    let releaseId: Int
    let token: String?

    init(releaseId: Int, token: String? = nil) {
        self.releaseId = releaseId
        self.token = token
        super.init()
    }
}
