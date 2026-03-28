import Foundation
import UniformTypeIdentifiers

/// Registry for content extractors
actor ContentExtractorRegistry {
    static let shared = ContentExtractorRegistry()

    private let extractors: [any ContentExtractor] = [
        URLExtractor(),
        ImageExtractor(),
        TextExtractor()
    ]

    private init() {}

    /// Extract content from an NSItemProvider
    func extract(from provider: NSItemProvider) async throws -> ExtractedContent {
        // Find the first extractor that can handle this provider
        for extractor in extractors {
            if extractor.canHandle(provider) {
                return try await extractor.extract(from: provider)
            }
        }

        // Fallback: try to get any text representation
        if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            let textExtractor = TextExtractor()
            return try await textExtractor.extract(from: provider)
        }

        throw ExtractionError.unsupportedType
    }
}

enum ExtractionError: LocalizedError {
    case unsupportedType
    case loadFailed(String)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .unsupportedType:
            return "Content type not supported"
        case .loadFailed(let reason):
            return "Failed to load content: \(reason)"
        case .invalidData:
            return "Invalid data received"
        }
    }
}
