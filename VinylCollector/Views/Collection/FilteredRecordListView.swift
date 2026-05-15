import SwiftUI
import SwiftData

enum StatFilter {
    case genre(String)
    case decade(Int)
    case condition(RecordCondition)
    case artist(String)

    var title: String {
        switch self {
        case .genre(let g): return g
        case .decade(let d): return "\(d)s"
        case .condition(let c): return c.displayName
        case .artist(let a): return a
        }
    }

    func matches(_ record: VinylRecord) -> Bool {
        switch self {
        case .genre(let g):
            return record.genres.contains(g)
        case .decade(let d):
            guard let year = record.year else { return false }
            return year / 10 * 10 == d
        case .condition(let c):
            return record.condition == c
        case .artist(let a):
            return record.artist == a
        }
    }
}

struct FilteredRecordListView: View {
    let filter: StatFilter
    @Query private var allRecords: [VinylRecord]

    private var displayRecords: [VinylRecord] {
        allRecords
            .filter { filter.matches($0) }
            .sorted { $0.artist < $1.artist }
    }

    var body: some View {
        List {
            ForEach(displayRecords) { record in
                NavigationLink(destination: RecordDetailView(record: record)) {
                    RecordRowView(record: record)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(filter.title)
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if displayRecords.isEmpty {
                ContentUnavailableView(
                    "No Records",
                    systemImage: "record.circle",
                    description: Text("No records match this filter.")
                )
            }
        }
    }
}
