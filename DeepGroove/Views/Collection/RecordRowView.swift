import SwiftUI

struct RecordRowView: View {
    let record: VinylRecord
    private let imageUtility = ImageUtility()

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
            VStack(alignment: .leading, spacing: 3) {
                Text(record.artist)
                    .font(.headline)
                    .lineLimit(1)
                Text(record.albumTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let year = record.year {
                        Text(String(year))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let label = record.label {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                conditionBadge
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var thumbnailView: some View {
        Group {
            if let photo = record.thumbnailPhoto,
               let image = imageUtility.loadThumbnail(path: photo.resolvedPath, maxPixelSize: 200) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
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

    private var conditionBadge: some View {
        Text(record.condition.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(conditionColor.opacity(0.15))
            .foregroundStyle(conditionColor)
            .clipShape(Capsule())
    }

    private var conditionColor: Color {
        switch record.condition {
        case .mint, .nearMint: .green
        case .veryGoodPlus, .veryGood: .blue
        case .goodPlus, .good: .orange
        case .fair, .poor: .red
        }
    }
}
