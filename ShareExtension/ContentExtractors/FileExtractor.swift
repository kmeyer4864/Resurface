import Foundation
import UniformTypeIdentifiers

/// Extracts generic file content from shared items (documents, spreadsheets, archives, audio, etc.)
/// This is a catch-all extractor for file types not handled by specific extractors (PDF, Image).
struct FileExtractor: ContentExtractor {
    static var supportedTypes: [UTType] = [.data, .item]

    func canHandle(_ provider: NSItemProvider) -> Bool {
        // Handle any file-like content that has a registered type
        // Check for file URL first (most common for file shares)
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            return true
        }
        // Fall back to generic data
        if provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
            return true
        }
        return false
    }

    func extract(from provider: NSItemProvider) async throws -> ExtractedContent {
        let (fileData, sourceURL, suggestedName) = try await loadFile(from: provider)

        // Determine file extension and MIME type from the URL or provider
        let fileExtension = resolveFileExtension(from: sourceURL, provider: provider)
        let mimeType = resolveMIMEType(from: fileExtension, provider: provider)
        let originalFilename = resolveFilename(from: sourceURL, suggestedName: suggestedName)

        var content = ExtractedContent(contentType: .file)
        content.fileData = fileData
        content.originalFilename = originalFilename
        content.fileExtension = fileExtension
        content.mimeType = mimeType
        content.url = sourceURL
        content.title = cleanDisplayTitle(from: originalFilename, fileExtension: fileExtension)

        return content
    }

    // MARK: - Private

    private func loadFile(from provider: NSItemProvider) async throws -> (Data, URL?, String?) {
        // Try file URL first for best metadata
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            return try await loadFromFileURL(provider: provider)
        }

        // Fall back to generic data loading
        return try await loadFromData(provider: provider)
    }

    private func loadFromFileURL(provider: NSItemProvider) async throws -> (Data, URL?, String?) {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: ExtractionError.loadFailed(error.localizedDescription))
                    return
                }

                if let url = item as? URL {
                    do {
                        let data = try Data(contentsOf: url)
                        continuation.resume(returning: (data, url, url.lastPathComponent))
                    } catch {
                        continuation.resume(throwing: ExtractionError.loadFailed("Could not read file: \(error.localizedDescription)"))
                    }
                } else {
                    continuation.resume(throwing: ExtractionError.invalidData)
                }
            }
        }
    }

    private func loadFromData(provider: NSItemProvider) async throws -> (Data, URL?, String?) {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: ExtractionError.loadFailed(error.localizedDescription))
                    return
                }

                if let data = item as? Data {
                    continuation.resume(returning: (data, nil, provider.suggestedName))
                } else if let url = item as? URL {
                    do {
                        let data = try Data(contentsOf: url)
                        continuation.resume(returning: (data, url, url.lastPathComponent))
                    } catch {
                        continuation.resume(throwing: ExtractionError.loadFailed("Could not read file"))
                    }
                } else {
                    continuation.resume(throwing: ExtractionError.invalidData)
                }
            }
        }
    }

    private func resolveFileExtension(from url: URL?, provider: NSItemProvider) -> String {
        // Try from URL
        if let url = url {
            let ext = url.pathExtension.lowercased()
            if !ext.isEmpty { return ext }
        }

        // Try from registered type identifiers
        for identifier in provider.registeredTypeIdentifiers {
            if let utType = UTType(identifier),
               let ext = utType.preferredFilenameExtension {
                return ext
            }
        }

        // Try from suggested name
        if let name = provider.suggestedName {
            let ext = (name as NSString).pathExtension.lowercased()
            if !ext.isEmpty { return ext }
        }

        return "dat"
    }

    private func resolveMIMEType(from fileExtension: String, provider: NSItemProvider) -> String {
        if let utType = UTType(filenameExtension: fileExtension),
           let mimeType = utType.preferredMIMEType {
            return mimeType
        }
        return "application/octet-stream"
    }

    private func resolveFilename(from url: URL?, suggestedName: String?) -> String {
        if let url = url {
            return url.lastPathComponent
        }
        return suggestedName ?? "Unknown File"
    }

    private func cleanDisplayTitle(from filename: String, fileExtension: String) -> String {
        // Remove extension for display
        var name = filename
        if name.lowercased().hasSuffix(".\(fileExtension)") {
            name = String(name.dropLast(fileExtension.count + 1))
        }

        // Replace underscores/dashes with spaces
        name = name.replacingOccurrences(of: "_", with: " ")
        name = name.replacingOccurrences(of: "-", with: " ")

        // Collapse multiple spaces
        while name.contains("  ") {
            name = name.replacingOccurrences(of: "  ", with: " ")
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? filename : trimmed
    }
}
