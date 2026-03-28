import Foundation

/// Provides thumbnail URLs for YouTube videos
struct YouTubeThumbnailProvider {
    /// YouTube thumbnail quality levels
    enum ThumbnailQuality: String, CaseIterable {
        /// Maximum resolution (1280x720), may not exist for all videos
        case maxres = "maxresdefault"

        /// Standard definition (640x480)
        case standard = "sddefault"

        /// High quality (480x360)
        case high = "hqdefault"

        /// Medium quality (320x180)
        case medium = "mqdefault"

        /// Default thumbnail (120x90)
        case thumbnail = "default"
    }

    /// Extract video ID from a YouTube URL
    /// - Parameter url: The YouTube URL
    /// - Returns: The video ID, or nil if not found
    static func extractVideoID(from url: URL) -> String? {
        // Handle youtu.be/VIDEO_ID format
        if let host = url.host, host.contains("youtu.be") {
            return url.pathComponents.last
        }

        // Handle youtube.com/watch?v=VIDEO_ID format
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            for item in queryItems where item.name == "v" {
                return item.value
            }
        }

        // Handle youtube.com/embed/VIDEO_ID format
        if url.pathComponents.contains("embed"), let videoID = url.pathComponents.last {
            return videoID
        }

        // Handle youtube.com/v/VIDEO_ID format
        if url.pathComponents.contains("v"), let videoID = url.pathComponents.last {
            return videoID
        }

        // Handle youtube.com/shorts/VIDEO_ID format
        if url.pathComponents.contains("shorts"), let videoID = url.pathComponents.last {
            return videoID
        }

        return nil
    }

    /// Get thumbnail URL for a YouTube video
    /// - Parameters:
    ///   - youtubeURL: The YouTube video URL
    ///   - quality: The desired thumbnail quality (default: high)
    /// - Returns: The thumbnail URL, or nil if video ID cannot be extracted
    static func thumbnailURL(for youtubeURL: URL, quality: ThumbnailQuality = .high) -> URL? {
        guard let videoID = extractVideoID(from: youtubeURL) else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(videoID)/\(quality.rawValue).jpg")
    }

    /// Get all available thumbnail URLs for a YouTube video (from highest to lowest quality)
    /// - Parameter youtubeURL: The YouTube video URL
    /// - Returns: Array of thumbnail URLs in quality order (highest first)
    static func allThumbnailURLs(for youtubeURL: URL) -> [URL] {
        guard let videoID = extractVideoID(from: youtubeURL) else { return [] }
        return ThumbnailQuality.allCases.compactMap { quality in
            URL(string: "https://img.youtube.com/vi/\(videoID)/\(quality.rawValue).jpg")
        }
    }

    /// Check if a URL is a YouTube URL
    /// - Parameter url: The URL to check
    /// - Returns: true if the URL is a YouTube URL
    static func isYouTubeURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("youtube.com") || host.contains("youtu.be")
    }

    /// Fetch the best available thumbnail for a YouTube video
    /// - Parameter youtubeURL: The YouTube video URL
    /// - Returns: Thumbnail data, or nil if fetching fails
    static func fetchThumbnail(for youtubeURL: URL) async -> Data? {
        let urls = allThumbnailURLs(for: youtubeURL)

        // Try each quality level until one succeeds
        for thumbnailURL in urls {
            do {
                let (data, response) = try await URLSession.shared.data(from: thumbnailURL)

                if let httpResponse = response as? HTTPURLResponse,
                   (200...299).contains(httpResponse.statusCode),
                   !data.isEmpty {
                    // Verify it's not the default "video not found" placeholder
                    // YouTube returns a 120x90 grey placeholder for non-existent videos
                    if let size = ImageResizer.imageDimensions(from: data),
                       size.width > 120 && size.height > 90 {
                        return data
                    }
                }
            } catch {
                // Try next quality level
                continue
            }
        }

        return nil
    }
}
