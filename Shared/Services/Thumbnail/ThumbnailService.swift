import Foundation
import UIKit

/// Generates and manages thumbnails for bookmark items
actor ThumbnailService {
    /// Shared instance
    static let shared = ThumbnailService()

    /// Default thumbnail size
    private let defaultSize: ImageResizer.ThumbnailSize = .medium

    /// Thumbnail directory name
    private let thumbnailDirectory = "thumbnails"

    private init() {}

    // MARK: - Public API

    /// Generate a thumbnail for a bookmark item
    /// - Parameters:
    ///   - item: The bookmark item
    ///   - metadata: Optional URL metadata (for URLs, contains image URLs)
    /// - Returns: Relative path to saved thumbnail, or nil if generation fails
    func generateThumbnail(for item: BookmarkItem, metadata: URLMetadata? = nil) async -> String? {
        switch item.contentType {
        case .url, .article:
            return await generateURLThumbnail(for: item, metadata: metadata)

        case .youtube:
            return await generateYouTubeThumbnail(for: item)

        case .image, .screenshot:
            return await generateImageThumbnail(for: item)

        case .video, .socialPost:
            return await generateURLThumbnail(for: item, metadata: metadata)

        case .text, .pdf, .unknown:
            return nil // No thumbnail for these types
        }
    }

    /// Load a thumbnail image from relative path
    /// - Parameter relativePath: The relative path returned by generateThumbnail
    /// - Returns: The thumbnail image, or nil if not found
    nonisolated func loadThumbnail(relativePath: String) -> UIImage? {
        guard let containerURL = AppGroupContainer.containerURL else { return nil }
        let fileURL = containerURL.appendingPathComponent("Documents/\(relativePath)")

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    /// Delete a thumbnail
    /// - Parameter relativePath: The relative path to the thumbnail
    func deleteThumbnail(relativePath: String) {
        guard let containerURL = AppGroupContainer.containerURL else { return }
        let fileURL = containerURL.appendingPathComponent("Documents/\(relativePath)")
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Private Thumbnail Generators

    /// Generate thumbnail for URL content
    private func generateURLThumbnail(for item: BookmarkItem, metadata: URLMetadata?) async -> String? {
        // Try OG image first
        if let imageURL = metadata?.imageURL {
            if let thumbnailPath = await downloadAndSaveThumbnail(from: imageURL, itemID: item.id) {
                return thumbnailPath
            }
        }

        // Try favicon/icon
        if let iconURL = metadata?.bestIconURL {
            if let thumbnailPath = await downloadAndSaveThumbnail(from: iconURL, itemID: item.id, isFavicon: true) {
                return thumbnailPath
            }
        }

        // Try constructing favicon URL from source URL
        if let sourceURL = item.sourceURL,
           let scheme = sourceURL.scheme,
           let host = sourceURL.host {
            let faviconURL = URL(string: "\(scheme)://\(host)/favicon.ico")
            if let faviconURL,
               let thumbnailPath = await downloadAndSaveThumbnail(from: faviconURL, itemID: item.id, isFavicon: true) {
                return thumbnailPath
            }
        }

        return nil
    }

    /// Generate thumbnail for YouTube content
    private func generateYouTubeThumbnail(for item: BookmarkItem) async -> String? {
        guard let sourceURL = item.sourceURL else { return nil }

        // Fetch YouTube thumbnail
        guard let imageData = await YouTubeThumbnailProvider.fetchThumbnail(for: sourceURL) else {
            return nil
        }

        // Resize and save
        guard let thumbnailData = ImageResizer.resize(imageData, to: defaultSize) else {
            return nil
        }

        return saveThumbnail(data: thumbnailData, itemID: item.id)
    }

    /// Generate thumbnail for image/screenshot content
    private func generateImageThumbnail(for item: BookmarkItem) async -> String? {
        guard let mediaPath = item.mediaPath,
              let containerURL = AppGroupContainer.containerURL else {
            return nil
        }

        let mediaURL = containerURL.appendingPathComponent("Documents/\(mediaPath)")

        guard let imageData = try? Data(contentsOf: mediaURL),
              let thumbnailData = ImageResizer.resize(imageData, to: defaultSize) else {
            return nil
        }

        return saveThumbnail(data: thumbnailData, itemID: item.id)
    }

    // MARK: - Helpers

    /// Download image from URL and save as thumbnail
    private func downloadAndSaveThumbnail(from url: URL, itemID: UUID, isFavicon: Bool = false) async -> String? {
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  !data.isEmpty else {
                return nil
            }

            // For favicons, we might want to handle smaller sizes differently
            let targetSize: ImageResizer.ThumbnailSize = isFavicon ? .small : defaultSize

            guard let thumbnailData = ImageResizer.resize(data, to: targetSize) else {
                // If resize fails, try to save original (might be SVG or other format)
                return nil
            }

            return saveThumbnail(data: thumbnailData, itemID: itemID)
        } catch {
            return nil
        }
    }

    /// Save thumbnail data to disk
    private func saveThumbnail(data: Data, itemID: UUID) -> String? {
        guard let containerURL = AppGroupContainer.containerURL else { return nil }

        let thumbnailDir = containerURL.appendingPathComponent("Documents/\(thumbnailDirectory)")

        // Ensure directory exists
        do {
            try FileManager.default.createDirectory(at: thumbnailDir, withIntermediateDirectories: true)
        } catch {
            return nil
        }

        let fileName = "\(itemID.uuidString)_thumb.jpg"
        let fileURL = thumbnailDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return "\(thumbnailDirectory)/\(fileName)"
        } catch {
            return nil
        }
    }

    /// Clean up orphaned thumbnails (thumbnails without matching items)
    func cleanupOrphanedThumbnails(validItemIDs: Set<UUID>) {
        guard let containerURL = AppGroupContainer.containerURL else { return }

        let thumbnailDir = containerURL.appendingPathComponent("Documents/\(thumbnailDirectory)")

        guard let contents = try? FileManager.default.contentsOfDirectory(at: thumbnailDir, includingPropertiesForKeys: nil) else {
            return
        }

        for fileURL in contents {
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            // Extract UUID from filename (format: UUID_thumb)
            let uuidString = fileName.replacingOccurrences(of: "_thumb", with: "")
            if let uuid = UUID(uuidString: uuidString), !validItemIDs.contains(uuid) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
}
