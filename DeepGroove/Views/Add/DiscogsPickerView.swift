import SwiftUI

// MARK: - Album group model

struct AlbumGroup: Identifiable, Hashable {
    let id: String  // album title key
    let albumTitle: String
    let artist: String
    let releases: [DiscogsSearchResult]

    var firstRelease: DiscogsSearchResult { releases[0] }

    static func == (lhs: AlbumGroup, rhs: AlbumGroup) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Main picker

struct DiscogsPickerView: View {
    let candidates: [DiscogsSearchResult]
    let hasMore: Bool
    let isLoadingMore: Bool
    let onSelect: (DiscogsSearchResult) -> Void
    let onNoMatch: () -> Void
    let onLoadMore: () -> Void

    @State private var selectedGroup: AlbumGroup?

    private let strings = StringUtility()

    private var groups: [AlbumGroup] {
        var order: [String] = []
        var dict: [String: [DiscogsSearchResult]] = [:]
        for result in candidates {
            let (_, album) = strings.splitDiscogsTitle(result.title)
            let key = album.isEmpty ? result.title : album
            if dict[key] == nil { order.append(key) }
            dict[key, default: []].append(result)
        }
        return order.compactMap { key -> AlbumGroup? in
            guard let releases = dict[key] else { return nil }
            let (artist, album) = strings.splitDiscogsTitle(releases[0].title)
            return AlbumGroup(id: key, albumTitle: album.isEmpty ? key : album,
                              artist: artist, releases: releases)
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(groups) { group in
                    if group.releases.count == 1 {
                        Button { onSelect(group.releases[0]) } label: { groupRow(group) }
                            .buttonStyle(.plain)
                    } else {
                        Button { selectedGroup = group } label: { groupRow(group) }
                            .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Select the correct release")
                    .textCase(nil)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if hasMore || isLoadingMore {
                Section {
                    Button(action: onLoadMore) {
                        HStack {
                            Spacer()
                            if isLoadingMore {
                                ProgressView().padding(.trailing, 6)
                                Text("Loading…").foregroundStyle(.secondary)
                            } else {
                                Text("Load More Results")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoadingMore)
                }
            }

            Section {
                Button { onNoMatch() } label: {
                    Label("None of these — enter manually", systemImage: "pencil")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Which release?")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedGroup) { group in
            ReleaseListView(group: group) { release in
                selectedGroup = nil
                onSelect(release)
            }
        }
    }

    private func groupRow(_ group: AlbumGroup) -> some View {
        HStack(spacing: 12) {
            albumArt(url: group.firstRelease.thumbURL)
            VStack(alignment: .leading, spacing: 3) {
                Text(group.albumTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if !group.artist.isEmpty {
                    Text(group.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if group.releases.count > 1 {
                    Text("\(group.releases.count) releases")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Image(systemName: group.releases.count > 1 ? "chevron.right" : "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(.vertical, 2)
    }

    private func albumArt(url: String?) -> some View {
        AsyncImage(url: URL(string: url ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Image(systemName: "record.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .background(Color(.systemGray5).clipShape(RoundedRectangle(cornerRadius: 6)))
    }
}

// MARK: - Release drill-down

private struct ReleaseListView: View {
    let group: AlbumGroup
    let onSelect: (DiscogsSearchResult) -> Void

    var body: some View {
        List {
            Section {
                ForEach(group.releases, id: \.id) { release in
                    releaseRow(release)
                }
            } header: {
                Text("Choose a pressing")
                    .textCase(nil)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(group.albumTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func releaseRow(_ result: DiscogsSearchResult) -> some View {
        Button { onSelect(result) } label: {
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

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if let year = result.year {
                            Text(year)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                        if let country = result.country {
                            Text(country)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                    if let label = result.labels.first {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if let catNo = result.catalogNumber {
                        Text(catNo)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Text("Select")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

