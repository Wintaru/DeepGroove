import Foundation

@Observable
final class CollectionViewModel {
    var searchText = ""
    var sortOrder: CollectionSortOrder = .artistAscending
    var showingFilters = false
    var showingAddRecord = false
    var errorMessage: String?

    var selectedGenres: Set<String> = []
    var selectedDecades: Set<Int> = []

    init() { }

    var hasActiveFilters: Bool {
        !selectedGenres.isEmpty || !selectedDecades.isEmpty
    }

    func clearFilters() {
        selectedGenres = []
        selectedDecades = []
        searchText = ""
    }
}
