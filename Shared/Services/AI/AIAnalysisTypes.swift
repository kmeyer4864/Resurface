import Foundation

/// Request sent to the Resurface AI backend
struct AIAnalysisRequest: Codable {
    let contentType: String
    let title: String
    let url: String?
    let rawText: String?
    let siteName: String?
    let imageDescription: String?

    // Category context for "lens" processing
    let categoryName: String?
    let categoryDescription: String?
    let categoryPrompt: String?

    init(from item: BookmarkItem) {
        self.contentType = item.contentType.rawValue
        self.title = item.title
        self.url = item.sourceURL?.absoluteString
        self.rawText = item.rawText ?? item.webContent?.extractedText
        self.siteName = item.webContent?.siteName
        self.imageDescription = nil // Future: Vision API for images

        // Include category context if available
        self.categoryName = item.category?.name
        self.categoryDescription = item.category?.categoryDescription
        self.categoryPrompt = item.category?.aiPrompt
    }
}

/// Response from the Resurface AI backend
struct AIAnalysisResponse: Codable {
    let category: String
    let tags: [String]
    let keyInsights: [String]
    let contentSubtype: String
    let confidence: Double

    // New fields for enhanced content understanding
    let suggestedTitle: String?           // Clean, human-readable title
    let extractedFields: [String: String]? // Category-specific key-value data
}

/// Error response from the backend
struct AIErrorResponse: Codable {
    let error: String
    let code: String
}

/// Errors that can occur during AI analysis
enum AIAnalysisError: LocalizedError {
    case networkUnavailable
    case serverError(Int, String)
    case decodingError(Error)
    case rateLimited(retryAfter: TimeInterval)
    case timeout
    case invalidResponse
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is not available"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .rateLimited(let retryAfter):
            return "Rate limited. Retry after \(Int(retryAfter)) seconds"
        case .timeout:
            return "Request timed out"
        case .invalidResponse:
            return "Invalid response from server"
        case .notConfigured:
            return "AI service not configured"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .rateLimited:
            return true
        case .serverError(let code, _):
            return code >= 500
        case .decodingError, .invalidResponse, .notConfigured:
            return false
        }
    }
}
