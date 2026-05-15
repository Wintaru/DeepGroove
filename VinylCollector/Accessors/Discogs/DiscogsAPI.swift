import Foundation

enum DiscogsAPI {
    static let searchURL = "https://api.discogs.com/database/search"
    static let releaseURL = "https://api.discogs.com/releases"
    static let userAgentHeaders = ["User-Agent": "VinylCollector/1.0"]
}
