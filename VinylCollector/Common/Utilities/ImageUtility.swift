import UIKit
import Vision

final class ImageUtility: Sendable {
    func compress(_ image: UIImage, maxDimension: CGFloat = 1024, quality: CGFloat = 0.8) -> Data? {
        let scaled = scale(image, maxDimension: maxDimension)
        return scaled.jpegData(compressionQuality: quality)
    }

    func toBase64(image: UIImage, maxDimension: CGFloat = 1024, quality: CGFloat = 0.8) -> String? {
        compress(image, maxDimension: maxDimension, quality: quality)?.base64EncodedString()
    }

    func loadFromDisk(path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }

    func saveToDisk(image: UIImage, directory: URL, filename: String) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw ImageError.compressionFailed
        }
        let fileURL = directory.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }

    func detectBarcode(in image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.ean13, .ean8, .upce, .code128, .code39, .qr]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        return (request.results as? [VNBarcodeObservation])?.first?.payloadStringValue
    }

    private func scale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

enum ImageError: Error, LocalizedError {
    case compressionFailed

    var errorDescription: String? { "Failed to compress image." }
}
