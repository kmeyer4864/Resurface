import Foundation
import UniformTypeIdentifiers

/// Protocol for extracting content from shared items
protocol ContentExtractor {
    /// The UTTypes this extractor can handle
    static var supportedTypes: [UTType] { get }

    /// Check if this extractor can handle the given provider
    func canHandle(_ provider: NSItemProvider) -> Bool

    /// Extract content from the provider
    func extract(from provider: NSItemProvider) async throws -> ExtractedContent
}

/// Extracted content from a shared item
struct ExtractedContent {
    var contentType: ContentType
    var title: String?
    var text: String?
    var url: URL?
    var imageData: Data?
    var metadata: [String: Any] = [:]
}
