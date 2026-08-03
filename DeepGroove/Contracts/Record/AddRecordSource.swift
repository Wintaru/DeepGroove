import UIKit

enum AddRecordSource {
    case photo(UIImage)
    case barcode(String)
    case text(artist: String, albumTitle: String)
    case manual
}
