import SwiftUI

struct ShareView: View {
    let vm: ShareViewModel

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 56)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .loading:
            loadingView
        case .confirming(let topMatch, _, let artist, _, _):
            confirmingView(result: topMatch, artist: artist)
        case .picking(let candidates, _, _, _):
            pickingView(candidates: candidates)
        case .fallback(let artist, let album, let year):
            fallbackView(artist: artist, album: album, year: year)
        case .queued(let album):
            queuedView(album: album)
        case .error(let message):
            errorView(message: message)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.2)
            Text("Searching Discogs…")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Confirming top match

    private func confirmingView(result: ShareDiscogsResult, artist: String) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 14) {
                thumbnailView(url: result.thumbURL, size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.albumTitle)
                        .font(.headline)
                        .lineLimit(2)
                    if let year = result.year {
                        Text("\(artist) · \(year)")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(artist)
                            .font(.subheadline).foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if let label = result.label {
                        Text(label)
                            .font(.caption).foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 12) {
                Button {
                    vm.confirmResult(result)
                } label: {
                    Label("Add to Wishlist", systemImage: "star.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Not this one — show all results") {
                    vm.showPicker()
                }
                .font(.subheadline)

                Button("Cancel") { vm.cancel() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Picker list

    private func pickingView(candidates: [ShareDiscogsResult]) -> some View {
        VStack(spacing: 16) {
            Text("Select the right release")
                .font(.title3).fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(candidates) { result in
                        Button {
                            vm.confirmResult(result)
                        } label: {
                            HStack(spacing: 12) {
                                thumbnailView(url: result.thumbURL, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.albumTitle)
                                        .font(.subheadline).fontWeight(.medium)
                                        .lineLimit(1)
                                    HStack(spacing: 4) {
                                        if let year = result.year {
                                            Text(year).font(.caption).foregroundStyle(.secondary)
                                        }
                                        if let label = result.label {
                                            Text("· \(label)").font(.caption).foregroundStyle(.tertiary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.blue)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                        }
                        .foregroundStyle(.primary)
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button("Cancel") { vm.cancel() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Fallback (no Discogs results)

    private func fallbackView(artist: String, album: String, year: String?) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 48)).foregroundStyle(.yellow)
            VStack(spacing: 4) {
                Text(album).font(.headline).multilineTextAlignment(.center)
                Text(artist).font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                vm.confirmFallback(artist: artist, album: album, year: year)
            } label: {
                Label("Add to Wishlist in Deep Groove", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Button("Cancel") { vm.cancel() }.foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Queued / Error

    private func queuedView(album: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48)).foregroundStyle(.green)
            Text("Added to Wishlist")
                .font(.headline)
            Text(album)
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 48)).foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Dismiss") { vm.cancel() }
                .buttonStyle(.bordered).controlSize(.large)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Thumbnail helper

    @ViewBuilder
    private func thumbnailView(url: String?, size: CGFloat) -> some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholderThumbnail
                    }
                }
            } else {
                placeholderThumbnail
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size > 50 ? 8 : 6))
    }

    private var placeholderThumbnail: some View {
        Color(.secondarySystemBackground)
            .overlay(
                Image(systemName: "record.circle")
                    .foregroundStyle(.tertiary)
            )
    }
}
