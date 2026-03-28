import Foundation
import UniformTypeIdentifiers
import UIKit

/// Extracts image content from shared items
struct ImageExtractor: ContentExtractor {
    static var supportedTypes: [UTType] = [.image, .jpeg, .png, .heic, .gif]

    func canHandle(_ provider: NSItemProvider) -> Bool {
        for type in Self.supportedTypes {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                return true
            }
        }
        return false
    }

    func extract(from provider: NSItemProvider) async throws -> ExtractedContent {
        let imageData = try await loadImage(from: provider)

        // Determine if this is a screenshot based on metadata or source
        let contentType: ContentType = .image

        var content = ExtractedContent(contentType: contentType)
        content.imageData = imageData
        content.title = "Image \(Date().formatted(date: .abbreviated, time: .shortened))"

        return content
    }

    private func loadImage(from provider: NSItemProvider) async throws -> Data {
        // Try each supported type
        for type in Self.supportedTypes {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                return try await loadData(from: provider, type: type)
            }
        }

        throw ExtractionError.unsupportedType
    }

    private func loadData(from provider: NSItemProvider, type: UTType) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: ExtractionError.loadFailed(error.localizedDescription))
                    return
                }

                if let data = item as? Data {
                    continuation.resume(returning: data)
                } else if let url = item as? URL, let data = try? Data(contentsOf: url) {
                    continuation.resume(returning: data)
                } else if let image = item as? UIImage, let data = image.jpegData(compressionQuality: 0.8) {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: ExtractionError.invalidData)
                }
            }
        }
    }
}
