import SwiftUI

struct DiscogsPickerView: View {
    let candidates: [DiscogsSearchResult]
    let identification: AIIdentification?
    let userPhoto: UIImage?
    let vm: AddRecordViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(candidates, id: \.id) { result in
                        Button { select(result) } label: { resultRow(result) }
                            .buttonStyle(.plain)
                    }
                } header: {
                    Text("Select the correct release")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        prefillManualEntry()
                    } label: {
                        Label("None of these — enter manually", systemImage: "pencil")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Which release?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.state = .selectSource
                    }
                }
            }
        }
    }

    private func resultRow(_ result: DiscogsSearchResult) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: result.thumbURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "record.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .background(Color(.systemGray5).clipShape(RoundedRectangle(cornerRadius: 6)))

            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let year = result.year {
                        Text(year).foregroundStyle(.secondary)
                    }
                    if let label = result.labels.first {
                        Text("·").foregroundStyle(.tertiary)
                        Text(label).foregroundStyle(.secondary)
                    }
                }
                .font(.caption)

                if let catNo = result.catalogNumber {
                    Text(catNo)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary).font(.caption)
        }
        .padding(.vertical, 2)
    }

    private func select(_ result: DiscogsSearchResult) {
        Task { await vm.confirmResult(result, identification: identification, userPhoto: userPhoto) }
    }

    private func prefillManualEntry() {
        vm.manualArtist = ""
        vm.manualAlbumTitle = ""
        vm.manualYear = ""
        vm.manualLabel = ""
        vm.state = .showingManualEntry
    }
}
