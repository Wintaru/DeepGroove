import Foundation

final class SearchDiscogsRequest: RequestBase, @unchecked Sendable {
    let query: String?        // general q= (fallback)
    let artist: String?       // artist= field search
    let releaseTitle: String? // release_title= field search
    let sort: String?         // e.g. "numhave"
    let sortOrder: String?    // "asc" or "desc"
    let country: String?      // e.g. "US", "UK"
    let token: String?
    let page: Int
    let perPage: Int

    init(
        query: String? = nil,
        artist: String? = nil,
        releaseTitle: String? = nil,
        sort: String? = nil,
        sortOrder: String? = nil,
        country: String? = nil,
        token: String? = nil,
        page: Int = 1,
        perPage: Int = 25
    ) {
        self.query = query
        self.artist = artist
        self.releaseTitle = releaseTitle
        self.sort = sort
        self.sortOrder = sortOrder
        self.country = country
        self.token = token
        self.page = page
        self.perPage = perPage
        super.init()
    }
}
