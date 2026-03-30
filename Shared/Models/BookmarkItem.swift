import Foundation
import SwiftData

@Model
final class BookmarkItem {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // Content
    var contentTypeRaw: String
    var title: String
    var rawText: String?
    var sourceURL: URL?
    var sourceApp: String?

    // Media
    var thumbnailPath: String?
    var mediaPath: String?
    var originalFilename: String?
    var mimeType: String?

    // Organization (AI-generated)
    var category: Category?
    var tags: [Tag] = []
    var keyInsights: [String] = []
    var contentSubtype: String?

    // AI-generated title (clean, human-readable)
    var aiGeneratedTitle: String?

    // Dynamic extracted fields (category-specific key-value data)
    // Stored as JSON string, parsed on access
    var extractedFieldsJSON: String?

    // Status
    var processingStatusRaw: String
    var isArchived: Bool
    var isFavorite: Bool

    // Processing tracking (Phase 1 completion)
    var lastProcessingError: String?
    var processingAttempts: Int = 0
    var lastProcessedAt: Date?

    // AI Processing (Phase 2)
    var aiProcessingStatusRaw: String = "pending"
    var aiProcessedAt: Date?
    var aiConfidence: Double?

    // Resurface Notifications
    var resurfaceAt: Date?              // When to send notification (nil = never)
    var resurfaceNotificationId: String? // For cancelling scheduled notification

    // Engagement tracking
    var lastViewedAt: Date?              // Set when user opens detail view
    var resurfaceDismissedAt: Date?      // Set when user dismisses from feed
    var resurfaceDismissCount: Int = 0   // Number of times dismissed (for backoff)

    // Auto-categorization tracking
    var wasAutoCategorized: Bool = false  // Whether AI assigned the category (vs. user manual pick)

    // Relationships
    @Relationship(deleteRule: .cascade)
    var webContent: WebContent?

    // MARK: - Computed Properties

    var contentType: ContentType {
        get { ContentType(rawValue: contentTypeRaw) ?? .unknown }
        set { contentTypeRaw = newValue.rawValue }
    }

    var processingStatus: ProcessingStatus {
        get { ProcessingStatus(rawValue: processingStatusRaw) ?? .pending }
        set { processingStatusRaw = newValue.rawValue }
    }

    var aiProcessingStatus: AIProcessingStatus {
        get { AIProcessingStatus(rawValue: aiProcessingStatusRaw) ?? .pending }
        set { aiProcessingStatusRaw = newValue.rawValue }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        contentType: ContentType,
        title: String,
        sourceURL: URL? = nil,
        sourceApp: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.contentTypeRaw = contentType.rawValue
        self.title = title
        self.sourceURL = sourceURL
        self.sourceApp = sourceApp
        self.processingStatusRaw = ProcessingStatus.pending.rawValue
        self.isArchived = false
        self.isFavorite = false
    }

    // MARK: - Methods

    func markUpdated() {
        updatedAt = Date()
    }
}

// MARK: - Convenience Extensions

extension BookmarkItem {
    var displayTitle: String {
        // Prefer AI-generated title
        if let aiTitle = aiGeneratedTitle, !aiTitle.isEmpty {
            return aiTitle
        }

        // Check if original title looks like a file path or UUID
        if !title.isEmpty && !looksLikeFilePath(title) {
            return title
        }

        return sourceURL?.host ?? "Untitled"
    }

    /// Check if a string looks like a file path or raw filename we should replace
    private func looksLikeFilePath(_ text: String) -> Bool {
        // Contains path separators
        if text.contains("/") { return true }

        // Starts with a UUID-like pattern (8-4-4-4-12 hex chars)
        let uuidPattern = #"^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}"#
        if let regex = try? NSRegularExpression(pattern: uuidPattern, options: .caseInsensitive) {
            let range = NSRange(text.startIndex..., in: text)
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                return true
            }
        }

        // Starts with common file name patterns
        let filePatterns = ["invoice_", "receipt_", "IMG_", "Screenshot", "document_"]
        for pattern in filePatterns {
            if text.hasPrefix(pattern) { return true }
        }

        return false
    }

    /// Category-specific extracted fields as a dictionary
    var extractedFields: [String: String] {
        get {
            guard let json = extractedFieldsJSON,
                  let data = json.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                extractedFieldsJSON = json
            }
        }
    }

    /// Ordered list of extracted field keys for display
    var extractedFieldKeys: [String] {
        // Return keys in a sensible order (alphabetical for now)
        extractedFields.keys.sorted()
    }

    var hasBeenViewed: Bool {
        lastViewedAt != nil
    }

    /// Resolves the relative mediaPath to an absolute file URL in the App Group container
    var resolvedMediaURL: URL? {
        guard let mediaPath = mediaPath,
              let container = AppGroupContainer.containerURL else { return nil }
        return container
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent(mediaPath)
    }

    var isPending: Bool {
        processingStatus == .pending
    }

    var isProcessed: Bool {
        processingStatus == .completed
    }

    var isAIProcessed: Bool {
        aiProcessingStatus == .completed
    }

    var needsAIProcessing: Bool {
        aiProcessingStatus == .pending || aiProcessingStatus == .failed
    }

    /// Whether this item has a resurface notification scheduled
    var hasResurfaceScheduled: Bool {
        resurfaceAt != nil && resurfaceNotificationId != nil
    }

    /// Whether the resurface time is in the future
    var isResurfacePending: Bool {
        guard let resurfaceAt = resurfaceAt else { return false }
        return resurfaceAt > Date()
    }

    /// Human-readable description of when this will resurface
    var resurfaceDescription: String? {
        guard let resurfaceAt = resurfaceAt else { return nil }

        if resurfaceAt <= Date() {
            return "Ready to resurface"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: resurfaceAt, relativeTo: Date())
    }
}
