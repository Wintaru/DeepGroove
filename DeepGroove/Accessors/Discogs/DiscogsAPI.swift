import Foundation

enum DiscogsAPI {
    static let searchURL = "https://api.discogs.com/database/search"
    static let releaseURL = "https://api.discogs.com/releases"
    static let masterURL = "https://api.discogs.com/masters"
    static let userAgentHeaders = ["User-Agent": "DeepGroove/1.0"]

    static func headers(token: String?) -> [String: String] {
        var h = userAgentHeaders
        if let token { h["Authorization"] = "Discogs token=\(token)" }
        return h
    }
}
