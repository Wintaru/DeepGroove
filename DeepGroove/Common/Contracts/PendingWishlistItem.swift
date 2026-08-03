import Foundation

// Transport DTO for the app-group hand-off between DeepGrooveShareExtension and the
// main app. Mirrors AddToWishlistRequest's fields losslessly (Codable, not a flattened
// [String: String]) so nothing is dropped or corrupted in transit.
struct PendingWishlistItem: Codable, Sendable {
    let chosenResult: DiscogsSearchResult?
    let artistOverride: String?
    let albumTitleOverride: String?
    let yearOverride: Int?
    let labelOverride: String?

    init(
        chosenResult: DiscogsSearchResult? = nil,
        artistOverride: String? = nil,
        albumTitleOverride: String? = nil,
        yearOverride: Int? = nil,
        labelOverride: String? = nil
    ) {
        self.chosenResult = chosenResult
        self.artistOverride = artistOverride
        self.albumTitleOverride = albumTitleOverride
        self.yearOverride = yearOverride
        self.labelOverride = labelOverride
    }

    var displayTitle: String {
        if let chosenResult { return chosenResult.title }
        return [artistOverride, albumTitleOverride].compactMap { $0 }.joined(separator: " – ")
    }
}

// Shared queue storage — appended to by the share extension, drained by the main app.
// A queue (not a single key) so sharing twice before reopening the app doesn't silently
// drop the first item. Not coordinated against a concurrent read-modify-write from the
// other process (no NSFileCoordinator) — an enqueue racing a drain in the same instant
// could still lose an item; narrow window, not fully closed here.
enum PendingWishlistQueue {
    private static let key = "pendingWishlistItems"

    @discardableResult
    static func enqueue(_ item: PendingWishlistItem) -> Bool {
        guard let defaults = UserDefaults(suiteName: AppGroup.id) else { return false }
        var items = readAll(from: defaults)
        items.append(item)
        guard let data = try? JSONEncoder().encode(items) else { return false }
        defaults.set(data, forKey: key)
        return true
    }

    static func drainAll() -> [PendingWishlistItem] {
        guard let defaults = UserDefaults(suiteName: AppGroup.id) else { return [] }
        let items = readAll(from: defaults)
        defaults.removeObject(forKey: key)
        return items
    }

    private static func readAll(from defaults: UserDefaults) -> [PendingWishlistItem] {
        guard let data = defaults.data(forKey: key),
              let items = try? JSONDecoder().decode([PendingWishlistItem].self, from: data)
        else { return [] }
        return items
    }
}
