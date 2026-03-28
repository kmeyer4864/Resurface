import Foundation

/// Extracted metadata from a URL
struct URLMetadata: Sendable {
    /// Page title from og:title or <title> tag
    let title: String?

    /// Page description from og:description or meta description
    let description: String?

    /// Site name from og:site_name
    let siteName: String?

    /// Author name if available
    let author: String?

    /// Publish date if available
    let publishDate: Date?

    /// URL to Open Graph image or preview image
    let imageURL: URL?

    /// URL to favicon
    let faviconURL: URL?

    /// Inline favicon data if available (avoids extra fetch)
    let faviconData: Data?

    /// URL to any icon (favicon or apple-touch-icon)
    let iconURL: URL?

    init(
        title: String? = nil,
        description: String? = nil,
        siteName: String? = nil,
        author: String? = nil,
        publishDate: Date? = nil,
        imageURL: URL? = nil,
        faviconURL: URL? = nil,
        faviconData: Data? = nil,
        iconURL: URL? = nil
    ) {
        self.title = title
        self.description = description
        self.siteName = siteName
        self.author = author
        self.publishDate = publishDate
        self.imageURL = imageURL
        self.faviconURL = faviconURL
        self.faviconData = faviconData
        self.iconURL = iconURL
    }

    /// Returns the best available title
    var displayTitle: String? {
        title ?? siteName
    }

    /// Returns the best available icon URL
    var bestIconURL: URL? {
        iconURL ?? faviconURL
    }

    /// Returns the best available image URL for thumbnail
    var thumbnailSourceURL: URL? {
        imageURL ?? bestIconURL
    }

    /// Merge with another metadata, preferring non-nil values from self
    func merging(with other: URLMetadata) -> URLMetadata {
        URLMetadata(
            title: title ?? other.title,
            description: description ?? other.description,
            siteName: siteName ?? other.siteName,
            author: author ?? other.author,
            publishDate: publishDate ?? other.publishDate,
            imageURL: imageURL ?? other.imageURL,
            faviconURL: faviconURL ?? other.faviconURL,
            faviconData: faviconData ?? other.faviconData,
            iconURL: iconURL ?? other.iconURL
        )
    }

    /// Empty metadata instance
    static let empty = URLMetadata()
}

/// Errors that can occur during metadata extraction
enum MetadataError: LocalizedError {
    /// Network is not available
    case networkUnavailable

    /// The provided URL is invalid
    case invalidURL

    /// Failed to fetch the URL content
    case fetchFailed(Error)

    /// Failed to parse the content
    case parsingFailed

    /// The request timed out
    case timeout

    /// The URL scheme is not supported (e.g., file://)
    case unsupportedScheme

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is not available"
        case .invalidURL:
            return "The URL is invalid"
        case .fetchFailed(let error):
            return "Failed to fetch URL: \(error.localizedDescription)"
        case .parsingFailed:
            return "Failed to parse page content"
        case .timeout:
            return "Request timed out"
        case .unsupportedScheme:
            return "URL scheme not supported"
        }
    }
}
