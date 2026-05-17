import SwiftUI
import SwiftData

struct FilteredRecordListView: View {
    let title: String
    let filter: CollectionFilter
    @EnvironmentObject private var container: DependencyContainer
    @Query private var allRecords: [VinylRecord]

    private var displayRecords: [VinylRecord] {
        CollectionSortOrder.artistAscending.apply(to: filter.applying(allRecords))
    }

    var body: some View {
        List {
            ForEach(displayRecords) { record in
                NavigationLink(destination: RecordDetailView(record: record, recordManager: container.recordManager)) {
                    RecordRowView(record: record)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if displayRecords.isEmpty {
                ContentUnavailableView(
                    "Lost in Space",
                    systemImage: "record.circle",
                    description: Text("No records found in this sector. Try a different filter.")
                )
            }
        }
    }
}
