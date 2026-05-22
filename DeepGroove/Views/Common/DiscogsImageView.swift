import SwiftUI

struct DiscogsImageView: View {
    let url: String?
    let size: CGFloat

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "record.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .background(Color(.systemGray5).clipShape(RoundedRectangle(cornerRadius: 6)))
        .task(id: url) {
            image = nil
            guard let urlString = url, let endpoint = URL(string: urlString) else { return }
            var request = URLRequest(url: endpoint)
            for (key, value) in DiscogsAPI.userAgentHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            guard let (data, _) = try? await URLSession.shared.data(for: request) else { return }
            image = UIImage(data: data)
        }
    }
}
