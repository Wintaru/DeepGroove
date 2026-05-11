import Foundation

@Observable
final class CollectionViewModel {
    var searchText = ""
    var sortOrder: CollectionSortOrder = .artistAscending
    var showingFilters = false
    var showingAddRecord = false
    var isDeleting = false
    var errorMessage: String?

    var selectedGenres: Set<String> = []
    var selectedDecades: Set<Int> = []

    private let recordManager: IRecordManager

    init(recordManager: IRecordManager) {
        self.recordManager = recordManager
    }

    var activeFilter: CollectionFilter {
        CollectionFilter(
            searchText: searchText.isEmpty ? nil : searchText,
            genres: selectedGenres.isEmpty ? nil : Array(selectedGenres)
        )
    }

    var hasActiveFilters: Bool {
        !selectedGenres.isEmpty || !selectedDecades.isEmpty
    }

    func delete(record: VinylRecord) async {
        isDeleting = true
        defer { isDeleting = false }
        let response = await recordManager.execute(RemoveRecordRequest(recordId: record.id))
        if !response.success {
            errorMessage = response.errorMessage ?? "Failed to delete record."
        }
    }

    func clearFilters() {
        selectedGenres = []
        selectedDecades = []
        searchText = ""
    }
}
