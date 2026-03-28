import Foundation

/// Manages access to the shared App Group container
enum AppGroupContainer {
    /// The App Group identifier - must match in both app and extension entitlements
    static let groupIdentifier = "group.com.keenanmeyer.resurface"

    /// The shared container URL
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
    }

    /// URL for the SwiftData database
    static var databaseURL: URL? {
        containerURL?
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("default.store")
    }

    /// Directory for storing media files (images, PDFs)
    static var mediaDirectory: URL? {
        guard let container = containerURL else { return nil }
        let url = container
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("media", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Directory for storing thumbnails
    static var thumbnailDirectory: URL? {
        guard let container = containerURL else { return nil }
        let url = container
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Temporary directory for processing
    static var tempDirectory: URL? {
        guard let container = containerURL else { return nil }
        let url = container.appendingPathComponent("tmp", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Validates that the App Group is properly configured
    static func validateConfiguration() -> Bool {
        guard let url = containerURL else {
            print("ERROR: App Group container not accessible. Check entitlements.")
            return false
        }
        print("App Group container: \(url.path)")
        return true
    }
}

// MARK: - File Storage Helpers

extension AppGroupContainer {
    /// Save data to the media directory, returning the relative path
    static func saveMedia(data: Data, filename: String) throws -> String {
        guard let mediaDir = mediaDirectory else {
            throw StorageError.containerNotAccessible
        }

        let fileURL = mediaDir.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return "media/\(filename)"
    }

    /// Save thumbnail data, returning the relative path
    static func saveThumbnail(data: Data, filename: String) throws -> String {
        guard let thumbDir = thumbnailDirectory else {
            throw StorageError.containerNotAccessible
        }

        let fileURL = thumbDir.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return "thumbnails/\(filename)"
    }

    /// Load data from a relative path
    static func loadData(relativePath: String) -> Data? {
        guard let container = containerURL else { return nil }
        let fileURL = container
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent(relativePath)
        return try? Data(contentsOf: fileURL)
    }

    /// Delete file at relative path
    static func deleteFile(relativePath: String) throws {
        guard let container = containerURL else {
            throw StorageError.containerNotAccessible
        }
        let fileURL = container
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent(relativePath)
        try FileManager.default.removeItem(at: fileURL)
    }

    /// Generate a unique filename with extension
    static func generateFilename(extension ext: String) -> String {
        "\(UUID().uuidString).\(ext)"
    }
}

// MARK: - Errors

enum StorageError: LocalizedError {
    case containerNotAccessible
    case fileNotFound
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .containerNotAccessible:
            return "App Group container is not accessible. Check entitlements."
        case .fileNotFound:
            return "File not found in storage."
        case .writeFailed(let error):
            return "Failed to write file: \(error.localizedDescription)"
        }
    }
}
