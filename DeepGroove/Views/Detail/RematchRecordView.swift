import SwiftUI

struct RematchRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm: RematchRecordViewModel

    init(record: VinylRecord, recordManager: IRecordManager) {
        _vm = State(initialValue: RematchRecordViewModel(record: record, recordManager: recordManager))
    }

    var body: some View {
        @Bindable var model = vm
        NavigationStack {
            Group {
                switch vm.state {
                case .editingSearch:
                    searchForm(model: $model)
                case .searching:
                    searchingView()
                case .applying:
                    applyingView()
                case .showingDiscogsResults(let candidates, let currentPage, let totalPages):
                    DiscogsPickerView(
                        candidates: candidates,
                        hasMore: currentPage < totalPages,
                        isLoadingMore: vm.isLoadingMore,
                        correctedArtist: nil,
                        onSelect: { result in Task { await vm.chooseResult(result) } },
                        onNoMatch: { vm.retrySearch() },
                        onLoadMore: { Task { await vm.loadMoreResults() } }
                    )
                case .success(let title):
                    successView(title)
                case .noResults(let message):
                    noResultsView(message: message,
                                  onTryAgain: { vm.retrySearch() },
                                  onEnterManually: { vm.retrySearch() })
                case .failure(let message):
                    failureView(message: message, onTryAgain: { vm.retrySearch() })
                }
            }
            .navigationTitle("Fix Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func searchForm(model: Bindable<RematchRecordViewModel>) -> some View {
        let canSearch = !vm.searchArtist.isEmpty || !vm.searchAlbumTitle.isEmpty
        return Form {
            Section("Search Discogs") {
                TextField("Artist", text: model.searchArtist)
                    .submitLabel(.next)
                TextField("Album Title", text: model.searchAlbumTitle)
                    .submitLabel(.search)
                    .onSubmit { if canSearch { Task { await vm.search() } } }
            }
            Section {
                Button {
                    Task { await vm.search() }
                } label: {
                    Label("Search Discogs", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canSearch)
            } footer: {
                Text("Pick a different release to update the title, artwork, and other details.")
            }
        }
    }

    private func applyingView() -> some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView().scaleEffect(1.5)
            Text("Updating Record…").font(.headline)
            Text("Fetching the new release's details and artwork")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private func successView(_ title: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72)).foregroundStyle(.green)
            VStack(spacing: 6) {
                Text("Match Updated").font(.title2).fontWeight(.bold)
                Text(title)
                    .font(.headline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Done") { dismiss() }.buttonStyle(.borderedProminent).controlSize(.large)
            Spacer()
        }
        .padding()
    }
}
