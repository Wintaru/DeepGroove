import Foundation

final class SearchITunesRequest: RequestBase, @unchecked Sendable {
    let artist: String
    let albumTitle: String

    init(artist: String, albumTitle: String) {
        self.artist = artist
        self.albumTitle = albumTitle
        super.init()
    }
}
