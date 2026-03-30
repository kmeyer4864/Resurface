import Foundation
import UniformTypeIdentifiers
import UIKit
import Vision

/// Extracts image content from shared items with OCR support
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

        // Perform OCR to extract text from image
        let extractedText = await performOCR(on: imageData)

        // Determine content type based on OCR results
        // If we got significant text, it's likely a screenshot
        let contentType: ContentType = (extractedText?.count ?? 0) > 50 ? .screenshot : .image

        // Determine actual image format from provider
        let fileExtension = resolveImageExtension(from: provider)
        let mimeType = UTType(filenameExtension: fileExtension)?.preferredMIMEType ?? "image/jpeg"

        var content = ExtractedContent(contentType: contentType)
        content.imageData = imageData
        content.fileData = imageData
        content.fileExtension = fileExtension
        content.mimeType = mimeType
        content.text = extractedText

        // Generate title from OCR text or use default
        if let text = extractedText, !text.isEmpty {
            content.title = generateTitle(from: text)
        } else {
            content.title = "Image \(Date().formatted(date: .abbreviated, time: .shortened))"
        }

        return content
    }

    /// Perform OCR on image data using Vision framework
    private func performOCR(on imageData: Data) async -> String? {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Extract text from all observations
                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: trimmed.isEmpty ? nil : trimmed)
            }

            // Configure for accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    /// Generate a title from extracted text
    private func generateTitle(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)

        // Find first meaningful line (not too short, not too long)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= 5 && trimmed.count <= 80 {
                return trimmed
            }
        }

        // Fallback: use first 50 chars
        let prefix = String(text.prefix(50)).trimmingCharacters(in: .whitespacesAndNewlines)
        if prefix.count >= 5 {
            return prefix + (text.count > 50 ? "..." : "")
        }

        return "Screenshot \(Date().formatted(date: .abbreviated, time: .shortened))"
    }

    /// Determine the actual image file extension from the provider's registered types
    private func resolveImageExtension(from provider: NSItemProvider) -> String {
        let typeToExtension: [(UTType, String)] = [
            (.png, "png"),
            (.heic, "heic"),
            (.gif, "gif"),
            (.jpeg, "jpg"),
        ]

        for (utType, ext) in typeToExtension {
            if provider.hasItemConformingToTypeIdentifier(utType.identifier) {
                return ext
            }
        }
        return "jpg"
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
