import Foundation
import UniformTypeIdentifiers

/// Extracts URL content from shared items
struct URLExtractor: ContentExtractor {
    static var supportedTypes: [UTType] = [.url, .fileURL]

    func canHandle(_ provider: NSItemProvider) -> Bool {
        provider.hasItemConformingToTypeIdentifier(UTType.url.identifier)
    }

    func extract(from provider: NSItemProvider) async throws -> ExtractedContent {
        let url = try await loadURL(from: provider)

        var content = ExtractedContent(contentType: .url, url: url)

        // Detect content type from URL
        if let host = url.host?.lowercased() {
            if host.contains("youtube.com") || host.contains("youtu.be") {
                content.contentType = .youtube
            } else if host.contains("twitter.com") || host.contains("x.com") ||
                      host.contains("instagram.com") || host.contains("tiktok.com") {
                content.contentType = .socialPost
            }
        }

        // Use the URL as the title for now
        // Full metadata extraction happens in the main app
        content.title = url.absoluteString

        return content
    }

    private func loadURL(from provider: NSItemProvider) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: ExtractionError.loadFailed(error.localizedDescription))
                    return
                }

                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: ExtractionError.invalidData)
                }
            }
        }
    }
}
