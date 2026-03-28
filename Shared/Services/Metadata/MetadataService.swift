import Foundation

/// Orchestrates metadata extraction from URLs using multiple providers with fallback
actor MetadataService {
    /// Shared instance
    static let shared = MetadataService()

    /// Timeout for LinkMetadataProvider before falling back
    private let primaryTimeout: TimeInterval = 5.0

    private init() {}

    /// Fetch metadata for a URL
    ///
    /// Attempts to use LinkMetadataProvider first (fast, respects robots.txt).
    /// Falls back to HTMLMetadataParser if LinkMetadataProvider fails.
    /// Always returns metadata (never throws) - may return partial or empty metadata.
    ///
    /// - Parameter url: The URL to fetch metadata for
    /// - Returns: Extracted URLMetadata (may be partial or empty)
    func fetchMetadata(for url: URL) async -> URLMetadata {
        // Try LinkMetadataProvider first with timeout
        do {
            let metadata = try await withTimeout(seconds: primaryTimeout) {
                try await LinkMetadataProvider.shared.fetchMetadata(for: url)
            }

            // If we got a title, consider it a success
            if metadata.title != nil {
                return metadata
            }

            // Otherwise, try to supplement with HTML parsing
            return await supplementWithHTMLParsing(metadata, url: url)

        } catch {
            // LinkMetadataProvider failed, fall back to HTML parsing
            return await fetchWithHTMLParser(url: url)
        }
    }

    /// Fetch metadata, throwing on failure
    ///
    /// Use this when you need to know if metadata extraction failed.
    ///
    /// - Parameter url: The URL to fetch metadata for
    /// - Returns: Extracted URLMetadata
    /// - Throws: MetadataError if extraction fails
    func fetchMetadataStrict(for url: URL) async throws -> URLMetadata {
        // Try LinkMetadataProvider first
        do {
            let metadata = try await withTimeout(seconds: primaryTimeout) {
                try await LinkMetadataProvider.shared.fetchMetadata(for: url)
            }

            if metadata.title != nil {
                return metadata
            }

            // Supplement with HTML parsing
            return await supplementWithHTMLParsing(metadata, url: url)

        } catch {
            // Fall back to HTML parsing
            return try await HTMLMetadataParser.fetch(url: url)
        }
    }

    // MARK: - Private Helpers

    /// Fetch metadata using only HTMLMetadataParser
    private func fetchWithHTMLParser(url: URL) async -> URLMetadata {
        do {
            return try await HTMLMetadataParser.fetch(url: url)
        } catch {
            // Return minimal metadata with just the URL info
            return URLMetadata(
                title: nil,
                description: nil,
                siteName: extractSiteName(from: url),
                author: nil,
                publishDate: nil,
                imageURL: nil,
                faviconURL: constructFaviconURL(from: url),
                faviconData: nil,
                iconURL: nil
            )
        }
    }

    /// Supplement existing metadata with HTML parsing
    private func supplementWithHTMLParsing(_ existing: URLMetadata, url: URL) async -> URLMetadata {
        do {
            let htmlMetadata = try await HTMLMetadataParser.fetch(url: url)
            return existing.merging(with: htmlMetadata)
        } catch {
            return existing
        }
    }

    /// Execute an async operation with a timeout
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw MetadataError.timeout
            }

            // Return the first result (either the operation completed or timeout)
            guard let result = try await group.next() else {
                throw MetadataError.timeout
            }

            // Cancel remaining tasks
            group.cancelAll()

            return result
        }
    }

    /// Extract site name from URL
    private func extractSiteName(from url: URL) -> String? {
        guard let host = url.host else { return nil }
        var siteName = host
        if siteName.hasPrefix("www.") {
            siteName = String(siteName.dropFirst(4))
        }
        let components = siteName.split(separator: ".")
        if let firstComponent = components.first {
            return String(firstComponent).capitalized
        }
        return nil
    }

    /// Construct favicon URL from base URL
    private func constructFaviconURL(from url: URL) -> URL? {
        guard let scheme = url.scheme, let host = url.host else { return nil }
        return URL(string: "\(scheme)://\(host)/favicon.ico")
    }
}

// MARK: - Convenience Extensions

extension MetadataService {
    /// Fetch metadata for a URL string
    func fetchMetadata(for urlString: String) async -> URLMetadata? {
        guard let url = URL(string: urlString) else { return nil }
        return await fetchMetadata(for: url)
    }
}
