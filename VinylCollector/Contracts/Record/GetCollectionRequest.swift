import Foundation

struct CollectionFilter: Sendable {
    var searchText: String?
    var genres: [String]?
    var artists: [String]?
    var yearRange: ClosedRange<Int>?
    var conditions: [RecordCondition]?
    var labels: [String]?

    var isEmpty: Bool {
        searchText == nil &&
        genres == nil &&
        artists == nil &&
        yearRange == nil &&
        conditions == nil &&
        labels == nil
    }
}

enum CollectionSortOrder: String, CaseIterable, Sendable {
    case artistAscending = "artist_asc"
    case artistDescending = "artist_desc"
    case titleAscending = "title_asc"
    case titleDescending = "title_desc"
    case yearNewest = "year_newest"
    case yearOldest = "year_oldest"
    case dateAddedNewest = "date_added_newest"
    case dateAddedOldest = "date_added_oldest"

    var displayName: String {
        switch self {
        case .artistAscending: "Artist (A–Z)"
        case .artistDescending: "Artist (Z–A)"
        case .titleAscending: "Title (A–Z)"
        case .titleDescending: "Title (Z–A)"
        case .yearNewest: "Year (Newest)"
        case .yearOldest: "Year (Oldest)"
        case .dateAddedNewest: "Recently Added"
        case .dateAddedOldest: "Oldest Added"
        }
    }

    func apply(to records: [VinylRecord]) -> [VinylRecord] {
        switch self {
        case .artistAscending:  return records.sorted { $0.artist < $1.artist }
        case .artistDescending: return records.sorted { $0.artist > $1.artist }
        case .titleAscending:   return records.sorted { $0.albumTitle < $1.albumTitle }
        case .titleDescending:  return records.sorted { $0.albumTitle > $1.albumTitle }
        case .yearNewest:       return records.sorted { ($0.year ?? 0) > ($1.year ?? 0) }
        case .yearOldest:       return records.sorted { ($0.year ?? 0) < ($1.year ?? 0) }
        case .dateAddedNewest:  return records.sorted { $0.dateAdded > $1.dateAdded }
        case .dateAddedOldest:  return records.sorted { $0.dateAdded < $1.dateAdded }
        }
    }
}

final class GetCollectionRequest: RequestBase, @unchecked Sendable {
    let filter: CollectionFilter
    let sortOrder: CollectionSortOrder
    let limit: Int?
    let offset: Int?

    init(
        filter: CollectionFilter = CollectionFilter(),
        sortOrder: CollectionSortOrder = .dateAddedNewest,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.filter = filter
        self.sortOrder = sortOrder
        self.limit = limit
        self.offset = offset
        super.init()
    }
}
