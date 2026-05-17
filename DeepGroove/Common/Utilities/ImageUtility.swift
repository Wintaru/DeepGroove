import UIKit
import Vision

private extension CGRect {
    var area: CGFloat { width * height }
}

private extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

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

    @discardableResult
    func saveToDisk(image: UIImage, directory: URL, filename: String, maxDimension: CGFloat = 1200) throws -> URL {
        let sized = scale(image, maxDimension: maxDimension)
        guard let data = sized.jpegData(compressionQuality: 0.85) else {
            throw ImageError.compressionFailed
        }
        let fileURL = directory.appendingPathComponent(filename)
        try data.write(to: fileURL, options: .completeFileProtectionUnlessOpen)
        return fileURL
    }

    // Loads a downsampled image using ImageIO — decodes only the pixels needed for the
    // target size rather than the full-resolution image, keeping memory use proportional
    // to the display size rather than the source file size.
    func loadThumbnail(path: String, maxPixelSize: Int) -> UIImage? {
        let url = URL(fileURLWithPath: path)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // Detects the most prominent rectangular region (e.g. an album cover) in the image.
    // Returns a normalized CGRect in UIKit coordinates (origin top-left), or nil if none found.
    func detectCoverRect(in image: UIImage) -> CGRect? {
        guard let cgImage = image.cgImage else { return nil }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let request = VNDetectRectanglesRequest()
        request.minimumSize = 0.2
        request.minimumConfidence = 0.4
        request.maximumObservations = 5
        request.quadratureTolerance = 30
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try? handler.perform([request])
        guard let observation = request.results?.max(by: { $0.boundingBox.area < $1.boundingBox.area })
        else { return nil }
        let box = observation.boundingBox
        // Vision uses bottom-left origin; convert to top-left
        return CGRect(x: box.minX, y: 1 - box.maxY, width: box.width, height: box.height)
    }

    // Crops an image to a normalized rect (UIKit coordinates, origin top-left).
    func crop(image: UIImage, to normalizedRect: CGRect) -> UIImage {
        let size = image.size
        let cropRect = CGRect(
            x: normalizedRect.minX * size.width,
            y: normalizedRect.minY * size.height,
            width: normalizedRect.width * size.width,
            height: normalizedRect.height * size.height
        )
        let renderer = UIGraphicsImageRenderer(size: cropRect.size)
        return renderer.image { _ in
            image.draw(at: CGPoint(x: -cropRect.minX, y: -cropRect.minY))
        }
    }

    func detectBarcode(in image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.ean13, .ean8, .upce, .code128, .code39, .qr]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        return request.results?.first?.payloadStringValue
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
