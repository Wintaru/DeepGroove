import SwiftUI

struct WishlistItemRowView: View {
    let item: WishlistRecord
    let onFoundIt: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
            VStack(alignment: .leading, spacing: 3) {
                Text(item.artist)
                    .font(.headline)
                    .lineLimit(1)
                Text(item.albumTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let year = item.year {
                        Text(String(year))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let label = item.label {
                        if item.year != nil {
                            Text("·").font(.caption).foregroundStyle(.secondary)
                        }
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                if let value = item.estimatedValue {
                    Text("~\(value, format: .currency(code: "USD"))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: onFoundIt) {
                Text("Found It")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var thumbnailView: some View {
        AsyncImage(url: URL(string: item.thumbURL ?? "")) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                Image(systemName: "record.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
        .frame(width: 56, height: 56)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
