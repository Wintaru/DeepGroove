import Foundation

final class SearchDiscogsRequest: RequestBase, @unchecked Sendable {
    let query: String?        // general q= (fallback)
    let artist: String?       // artist= field search
    let releaseTitle: String? // release_title= field search
    let sort: String?         // e.g. "have"
    let sortOrder: String?    // "asc" or "desc"
    let token: String?
    let page: Int

    init(
        query: String? = nil,
        artist: String? = nil,
        releaseTitle: String? = nil,
        sort: String? = nil,
        sortOrder: String? = nil,
        token: String? = nil,
        page: Int = 1
    ) {
        self.query = query
        self.artist = artist
        self.releaseTitle = releaseTitle
        self.sort = sort
        self.sortOrder = sortOrder
        self.token = token
        self.page = page
        super.init()
    }
}
