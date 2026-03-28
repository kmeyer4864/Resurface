import Foundation
import LinkPresentation
import UIKit

/// Provides URL metadata using Apple's LinkPresentation framework
actor LinkMetadataProvider {
    /// Shared instance
    static let shared = LinkMetadataProvider()

    /// Default timeout for metadata fetching
    private let timeout: TimeInterval = 10.0

    private init() {}

    /// Fetch metadata for a URL using LPMetadataProvider
    /// - Parameter url: The URL to fetch metadata for
    /// - Returns: Extracted URLMetadata
    /// - Throws: MetadataError if fetching fails
    func fetchMetadata(for url: URL) async throws -> URLMetadata {
        guard url.scheme == "http" || url.scheme == "https" else {
            throw MetadataError.unsupportedScheme
        }

        let provider = LPMetadataProvider()
        provider.timeout = timeout

        do {
            let metadata = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<LPLinkMetadata, Error>) in
                provider.startFetchingMetadata(for: url) { metadata, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let metadata = metadata {
                        continuation.resume(returning: metadata)
                    } else {
                        continuation.resume(throwing: MetadataError.parsingFailed)
                    }
                }
            }

            return await convertMetadata(metadata, originalURL: url)
        } catch let error as MetadataError {
            throw error
        } catch {
            // Check for common error types
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorTimedOut:
                    throw MetadataError.timeout
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorNetworkConnectionLost:
                    throw MetadataError.networkUnavailable
                default:
                    throw MetadataError.fetchFailed(error)
                }
            }
            throw MetadataError.fetchFailed(error)
        }
    }

    /// Convert LPLinkMetadata to URLMetadata
    private func convertMetadata(_ lpMetadata: LPLinkMetadata, originalURL: URL) async -> URLMetadata {
        let title = lpMetadata.title
        var imageData: Data?
        var iconData: Data?
        var imageURL: URL?

        // Extract image data from imageProvider
        if let imageProvider = lpMetadata.imageProvider {
            imageData = await loadImageData(from: imageProvider)
        }

        // Extract icon data from iconProvider
        if let iconProvider = lpMetadata.iconProvider {
            iconData = await loadImageData(from: iconProvider)
        }

        // Try to get remote URL if available
        if let remoteURL = lpMetadata.remoteVideoURL {
            // For video content, we might want to use video thumbnail
            imageURL = remoteURL
        }

        // Construct favicon URL from base domain
        let faviconURL = constructFaviconURL(from: originalURL)

        return URLMetadata(
            title: title,
            description: nil, // LPMetadataProvider doesn't provide description
            siteName: extractSiteName(from: originalURL),
            author: nil,
            publishDate: nil,
            imageURL: imageURL,
            faviconURL: faviconURL,
            faviconData: iconData ?? imageData,
            iconURL: faviconURL
        )
    }

    /// Load image data from NSItemProvider
    private func loadImageData(from provider: NSItemProvider) async -> Data? {
        // Try to load as UIImage first
        if provider.canLoadObject(ofClass: UIImage.self) {
            do {
                let image = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UIImage, Error>) in
                    provider.loadObject(ofClass: UIImage.self) { object, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let image = object as? UIImage {
                            continuation.resume(returning: image)
                        } else {
                            continuation.resume(throwing: MetadataError.parsingFailed)
                        }
                    }
                }
                return image.jpegData(compressionQuality: 0.8)
            } catch {
                // Fall through to try data loading
            }
        }

        // Try to load as Data
        if provider.hasItemConformingToTypeIdentifier("public.image") {
            do {
                let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
                    provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let data = data {
                            continuation.resume(returning: data)
                        } else {
                            continuation.resume(throwing: MetadataError.parsingFailed)
                        }
                    }
                }
                return data
            } catch {
                return nil
            }
        }

        return nil
    }

    /// Construct favicon URL from base URL
    private func constructFaviconURL(from url: URL) -> URL? {
        guard let scheme = url.scheme, let host = url.host else { return nil }
        return URL(string: "\(scheme)://\(host)/favicon.ico")
    }

    /// Extract site name from URL host
    private func extractSiteName(from url: URL) -> String? {
        guard let host = url.host else { return nil }

        // Remove www. prefix and extract domain name
        var siteName = host
        if siteName.hasPrefix("www.") {
            siteName = String(siteName.dropFirst(4))
        }

        // Capitalize first letter of each word in domain
        let components = siteName.split(separator: ".")
        if let firstComponent = components.first {
            return String(firstComponent).capitalized
        }

        return siteName
    }
}
