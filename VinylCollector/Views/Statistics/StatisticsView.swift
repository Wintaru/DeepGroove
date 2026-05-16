import SwiftUI

struct StatisticsView: View {
    @State private var vm: StatisticsViewModel

    init(statisticsManager: IStatisticsManager) {
        _vm = State(initialValue: StatisticsViewModel(statisticsManager: statisticsManager))
    }

    var body: some View {
        @Bindable var vm = vm
        return NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Loading statistics…")
                } else if let stats = vm.statistics {
                    statisticsContent(stats)
                } else {
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "chart.bar",
                        description: Text("Add records to your collection to see statistics.")
                    )
                }
            }
            .navigationTitle("Statistics")
            .errorAlert(message: $vm.errorMessage)
        }
        .task {
            await vm.load()
        }
    }

    private func statisticsContent(_ stats: CollectionStatistics) -> some View {
        List {
            Section {
                HStack {
                    statCard(value: "\(stats.totalRecords)", label: "Records",
                             icon: "record.circle", color: .blue)
                    statCard(value: stats.totalEstimatedValue > 0
                             ? String(format: "$%.0f", stats.totalEstimatedValue) : "–",
                             label: "Est. Value", icon: "dollarsign.circle", color: .green)
                }
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
            }

            if !stats.topArtists.isEmpty {
                Section("Top Artists") {
                    ForEach(stats.topArtists, id: \.artist) { stat in
                        NavigationLink(destination: FilteredRecordListView(title: stat.artist, filter: CollectionFilter(artists: [stat.artist]))) {
                            HStack {
                                Text(stat.artist)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(stat.recordCount)")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }

            if !stats.genreBreakdown.isEmpty {
                Section("Genres") {
                    ForEach(stats.genreBreakdown, id: \.genre) { stat in
                        NavigationLink(destination: FilteredRecordListView(title: stat.genre, filter: CollectionFilter(genres: [stat.genre]))) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(stat.genre)
                                    Spacer()
                                    Text(String(format: "%.0f%%", stat.percentage))
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.accentColor)
                                        .frame(width: geo.size.width * (stat.percentage / 100))
                                        .frame(height: 4)
                                }
                                .frame(height: 4)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }

            if !stats.decadeBreakdown.isEmpty {
                Section("By Decade") {
                    ForEach(stats.decadeBreakdown, id: \.decade) { stat in
                        NavigationLink(destination: FilteredRecordListView(title: "\(String(stat.decade))s", filter: CollectionFilter(decades: [stat.decade]))) {
                            HStack {
                                Text(verbatim: "\(String(stat.decade))s")
                                Spacer()
                                Text("\(stat.recordCount) records")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }

            if !stats.conditionBreakdown.isEmpty {
                Section("Condition") {
                    ForEach(RecordCondition.allCases.filter { stats.conditionBreakdown[$0] != nil },
                            id: \.self) { condition in
                        NavigationLink(destination: FilteredRecordListView(title: condition.displayName, filter: CollectionFilter(conditions: [condition]))) {
                            HStack {
                                Text(condition.displayName)
                                Spacer()
                                Text("\(stats.conditionBreakdown[condition] ?? 0)")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(4)
    }
}
