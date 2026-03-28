import Foundation
import UniformTypeIdentifiers

/// Extracts text content from shared items
struct TextExtractor: ContentExtractor {
    static var supportedTypes: [UTType] = [.text, .plainText, .utf8PlainText]

    func canHandle(_ provider: NSItemProvider) -> Bool {
        for type in Self.supportedTypes {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                return true
            }
        }
        return false
    }

    func extract(from provider: NSItemProvider) async throws -> ExtractedContent {
        let text = try await loadText(from: provider)

        var content = ExtractedContent(contentType: .text)
        content.text = text

        // Use first line or truncated text as title
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        content.title = String(firstLine.prefix(100))

        return content
    }

    private func loadText(from provider: NSItemProvider) async throws -> String {
        // Try each text type
        for type in Self.supportedTypes {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                return try await loadString(from: provider, type: type)
            }
        }

        throw ExtractionError.unsupportedType
    }

    private func loadString(from provider: NSItemProvider, type: UTType) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: ExtractionError.loadFailed(error.localizedDescription))
                    return
                }

                if let string = item as? String {
                    continuation.resume(returning: string)
                } else if let data = item as? Data, let string = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: string)
                } else {
                    continuation.resume(throwing: ExtractionError.invalidData)
                }
            }
        }
    }
}
