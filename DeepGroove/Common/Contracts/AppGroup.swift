import Foundation

// Shared app-group identifier — used by APIConfiguration (Keychain access group),
// DeepGrooveShareExtension's Keychain read, and PendingWishlistQueue (UserDefaults suite).
// One source of truth so the three don't silently drift out of sync.
enum AppGroup {
    static let id = "group.com.jdonner.deepgroove"
}
