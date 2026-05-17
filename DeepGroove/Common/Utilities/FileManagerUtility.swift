import Foundation

final class FileManagerUtility: Sendable {
    var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var photosDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("RecordPhotos")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // Resolves a stored relative path (e.g. "RecordPhotos/uuid.jpg") to the current absolute path.
    func resolvedPath(for relativePath: String) -> String {
        documentsDirectory.appendingPathComponent(relativePath).path
    }

    func removeFiles(atRelativePaths paths: [String]) {
        for path in paths {
            try? FileManager.default.removeItem(atPath: resolvedPath(for: path))
        }
    }
}
