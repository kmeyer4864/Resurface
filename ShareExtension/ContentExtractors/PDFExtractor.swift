import Foundation
import UniformTypeIdentifiers
import PDFKit

/// Extracts text content from PDF files
struct PDFExtractor: ContentExtractor {
    static var supportedTypes: [UTType] = [.pdf]

    func canHandle(_ provider: NSItemProvider) -> Bool {
        provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier)
    }

    func extract(from provider: NSItemProvider) async throws -> ExtractedContent {
        let (pdfData, sourceURL) = try await loadPDF(from: provider)

        // Extract text from PDF
        let extractedText = extractText(from: pdfData)

        var content = ExtractedContent(contentType: .pdf)
        content.text = extractedText
        content.imageData = pdfData // Store PDF data for later access
        content.url = sourceURL

        // Try to get a reasonable title from the filename or first line of text
        if let url = sourceURL {
            let filename = url.deletingPathExtension().lastPathComponent
            // Clean up filename - remove UUIDs and common prefixes
            content.title = cleanFilename(filename)
        } else if let text = extractedText, !text.isEmpty {
            // Use first meaningful line as title
            content.title = extractFirstLine(from: text)
        } else {
            content.title = "PDF Document"
        }

        return content
    }

    private func loadPDF(from provider: NSItemProvider) async throws -> (Data, URL?) {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: ExtractionError.loadFailed(error.localizedDescription))
                    return
                }

                if let url = item as? URL {
                    // Load from file URL
                    if let data = try? Data(contentsOf: url) {
                        continuation.resume(returning: (data, url))
                    } else {
                        continuation.resume(throwing: ExtractionError.loadFailed("Could not read PDF file"))
                    }
                } else if let data = item as? Data {
                    continuation.resume(returning: (data, nil))
                } else {
                    continuation.resume(throwing: ExtractionError.invalidData)
                }
            }
        }
    }

    private func extractText(from pdfData: Data) -> String? {
        guard let document = PDFDocument(data: pdfData) else { return nil }

        var fullText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i),
               let pageText = page.string {
                fullText += pageText + "\n"
            }
        }

        let trimmed = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func cleanFilename(_ filename: String) -> String {
        var cleaned = filename

        // Remove UUID patterns (8-4-4-4-12 hex format)
        let uuidPattern = #"[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}"#
        if let regex = try? NSRegularExpression(pattern: uuidPattern) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
        }

        // Replace underscores and dashes with spaces
        cleaned = cleaned.replacingOccurrences(of: "_", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "-", with: " ")

        // Remove multiple spaces
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractFirstLine(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= 3 && trimmed.count <= 100 {
                return trimmed
            }
        }
        return "PDF Document"
    }
}
