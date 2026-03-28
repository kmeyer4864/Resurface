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

    // Organization (AI-generated)
    var category: Category?
    var tags: [Tag] = []
    var keyInsights: [String] = []
    var contentSubtype: String?

    // Status
    var processingStatusRaw: String
    var isArchived: Bool
    var isFavorite: Bool

    // Processing tracking (Phase 1 completion)
    var lastProcessingError: String?
    var processingAttempts: Int = 0
    var lastProcessedAt: Date?

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
        if title.isEmpty {
            return sourceURL?.host ?? "Untitled"
        }
        return title
    }

    var isPending: Bool {
        processingStatus == .pending
    }

    var isProcessed: Bool {
        processingStatus == .completed
    }
}
