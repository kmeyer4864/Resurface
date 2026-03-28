import Foundation
import SwiftData

/// Processes pending bookmark items in the background
@Observable
@MainActor
final class BackgroundProcessor {
    /// Shared instance
    static let shared = BackgroundProcessor()

    /// Whether processing is currently active
    private(set) var isProcessing: Bool = false

    /// Number of items currently pending
    private(set) var pendingCount: Int = 0

    /// Maximum number of processing attempts before marking as failed
    private let maxAttempts = 3

    /// Processing semaphore to prevent concurrent processing
    private var processingTask: Task<Void, Never>?

    private init() {}

    // MARK: - Public API

    /// Process all pending bookmark items
    /// - Parameter context: The model context to use
    func processPendingItems(in context: ModelContext) async {
        // Prevent concurrent processing
        guard processingTask == nil else { return }

        isProcessing = true

        processingTask = Task {
            await performProcessing(in: context)
            processingTask = nil
            isProcessing = false
        }

        await processingTask?.value
    }

    /// Process a single item
    /// - Parameters:
    ///   - item: The item to process
    ///   - context: The model context to use
    func processItem(_ item: BookmarkItem, in context: ModelContext) async {
        guard item.processingStatus == .pending || item.processingStatus == .failed else {
            return
        }

        await processBookmarkItem(item, in: context)
    }

    /// Cancel any ongoing processing
    func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
        isProcessing = false
    }

    // MARK: - Private Processing Logic

    /// Perform the actual processing
    private func performProcessing(in context: ModelContext) async {
        // Check network availability
        guard NetworkMonitor.shared.isConnected else {
            return
        }

        // Fetch pending items
        let descriptor = FetchDescriptor<BookmarkItem>(
            predicate: #Predicate<BookmarkItem> { item in
                item.processingStatusRaw == "pending" || item.processingStatusRaw == "failed"
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        guard let items = try? context.fetch(descriptor) else {
            return
        }

        pendingCount = items.count

        // Filter out items with too many attempts
        let itemsToProcess = items.filter { $0.processingAttempts < maxAttempts }

        for item in itemsToProcess {
            // Check if cancelled
            if Task.isCancelled { break }

            // Check network for each item (might have disconnected)
            guard NetworkMonitor.shared.isConnected else { break }

            await processBookmarkItem(item, in: context)
            pendingCount = max(0, pendingCount - 1)
        }

        pendingCount = 0
    }

    /// Process a single bookmark item
    private func processBookmarkItem(_ item: BookmarkItem, in context: ModelContext) async {
        item.processingStatus = .processing
        item.processingAttempts += 1

        // Fetch metadata for URLs
        if let sourceURL = item.sourceURL, item.contentType.requiresMetadataFetch {
            let metadata = await MetadataService.shared.fetchMetadata(for: sourceURL)

            // Update item with metadata
            updateItemWithMetadata(item, metadata: metadata)

            // Generate thumbnail
            if let thumbnailPath = await ThumbnailService.shared.generateThumbnail(for: item, metadata: metadata) {
                item.thumbnailPath = thumbnailPath
            }

            // Create or update WebContent
            updateWebContent(for: item, metadata: metadata, in: context)
        } else if item.contentType == .image || item.contentType == .screenshot {
            // Generate thumbnail for images
            if let thumbnailPath = await ThumbnailService.shared.generateThumbnail(for: item) {
                item.thumbnailPath = thumbnailPath
            }
        }

        // Mark as completed
        item.processingStatus = .completed
        item.lastProcessedAt = Date()
        item.lastProcessingError = nil

        // Save changes
        item.markUpdated()
        try? context.save()
    }

    /// Update item with extracted metadata
    private func updateItemWithMetadata(_ item: BookmarkItem, metadata: URLMetadata) {
        // Update title if we got a better one
        if let title = metadata.displayTitle, !title.isEmpty {
            // Only update if current title is just the URL
            if item.title == item.sourceURL?.absoluteString || item.title == "Untitled" {
                item.title = title
            }
        }

        // Store raw text from description for search
        if let description = metadata.description, item.rawText == nil {
            item.rawText = description
        }
    }

    /// Create or update WebContent for an item
    private func updateWebContent(for item: BookmarkItem, metadata: URLMetadata, in context: ModelContext) {
        guard let sourceURL = item.sourceURL else { return }

        if item.webContent == nil {
            let webContent = WebContent(
                url: sourceURL,
                extractedText: metadata.description ?? ""
            )
            webContent.siteName = metadata.siteName
            webContent.author = metadata.author
            webContent.publishDate = metadata.publishDate
            webContent.ogImageURL = metadata.imageURL
            webContent.metadataFetchedAt = Date()

            item.webContent = webContent
            context.insert(webContent)
        } else {
            // Update existing WebContent
            item.webContent?.siteName = metadata.siteName
            item.webContent?.author = metadata.author
            item.webContent?.publishDate = metadata.publishDate
            item.webContent?.ogImageURL = metadata.imageURL
            item.webContent?.metadataFetchedAt = Date()

            if let description = metadata.description, !description.isEmpty {
                item.webContent?.extractedText = description
            }
        }
    }
}

// MARK: - ContentType Extension

extension ContentType {
    /// Whether this content type requires metadata fetching
    var requiresMetadataFetch: Bool {
        switch self {
        case .url, .article, .youtube, .video, .socialPost:
            return true
        case .image, .screenshot, .text, .pdf, .unknown:
            return false
        }
    }
}
