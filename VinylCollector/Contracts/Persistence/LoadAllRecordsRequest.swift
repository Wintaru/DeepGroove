import Foundation

final class LoadAllRecordsRequest: RequestBase {
    let filter: CollectionFilter
    let sortOrder: CollectionSortOrder

    init(filter: CollectionFilter = CollectionFilter(), sortOrder: CollectionSortOrder = .dateAddedNewest) {
        self.filter = filter
        self.sortOrder = sortOrder
        super.init()
    }
}
