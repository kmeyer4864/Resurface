import XCTest
import SwiftData
@testable import Resurface

/// Tests for the Phase 1 data flow: Share Extension → Background Processing → UI
final class DataFlowTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        // Create in-memory container for testing
        let schema = Schema([
            BookmarkItem.self,
            Category.self,
            Tag.self,
            WebContent.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - BookmarkItem Creation Tests

    func testBookmarkItemCreation() throws {
        // Given
        let url = URL(string: "https://example.com/article")!

        // When
        let item = BookmarkItem(
            contentType: .url,
            title: "Test Article",
            sourceURL: url
        )
        modelContext.insert(item)
        try modelContext.save()

        // Then
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.contentType, .url)
        XCTAssertEqual(item.title, "Test Article")
        XCTAssertEqual(item.sourceURL, url)
        XCTAssertEqual(item.processingStatus, .pending)
        XCTAssertFalse(item.isArchived)
        XCTAssertFalse(item.isFavorite)
        XCTAssertEqual(item.processingAttempts, 0)
    }

    func testBookmarkItemDefaultStatus() {
        // Given/When
        let item = BookmarkItem(
            contentType: .article,
            title: "Test"
        )

        // Then
        XCTAssertEqual(item.processingStatus, .pending)
        XCTAssertTrue(item.isPending)
        XCTAssertFalse(item.isProcessed)
    }

    func testBookmarkItemProcessingTracking() throws {
        // Given
        let item = BookmarkItem(contentType: .url, title: "Test")
        modelContext.insert(item)

        // When - simulate processing
        item.processingStatus = .processing
        item.processingAttempts = 1
        try modelContext.save()

        // Then
        XCTAssertEqual(item.processingAttempts, 1)
        XCTAssertEqual(item.processingStatus, .processing)

        // When - complete processing
        item.processingStatus = .completed
        item.lastProcessedAt = Date()
        try modelContext.save()

        // Then
        XCTAssertTrue(item.isProcessed)
        XCTAssertNotNil(item.lastProcessedAt)
    }

    func testBookmarkItemProcessingError() throws {
        // Given
        let item = BookmarkItem(contentType: .url, title: "Test")
        modelContext.insert(item)

        // When - simulate failure
        item.processingStatus = .failed
        item.lastProcessingError = "Network unavailable"
        item.processingAttempts = 1
        try modelContext.save()

        // Then
        XCTAssertEqual(item.processingStatus, .failed)
        XCTAssertEqual(item.lastProcessingError, "Network unavailable")
        XCTAssertEqual(item.processingAttempts, 1)
    }

    // MARK: - WebContent Tests

    func testWebContentCreation() throws {
        // Given
        let url = URL(string: "https://example.com")!

        // When
        let webContent = WebContent(
            url: url,
            extractedText: "This is the article content",
            author: "John Doe",
            siteName: "Example"
        )
        modelContext.insert(webContent)
        try modelContext.save()

        // Then
        XCTAssertEqual(webContent.url, url)
        XCTAssertEqual(webContent.extractedText, "This is the article content")
        XCTAssertEqual(webContent.author, "John Doe")
        XCTAssertEqual(webContent.siteName, "Example")
    }

    func testWebContentWithMetadataFields() throws {
        // Given
        let url = URL(string: "https://example.com")!
        let ogImageURL = URL(string: "https://example.com/og-image.jpg")

        // When
        let webContent = WebContent(
            url: url,
            extractedText: "Content",
            faviconPath: "thumbnails/favicon.png",
            ogImageURL: ogImageURL,
            metadataFetchedAt: Date()
        )
        modelContext.insert(webContent)
        try modelContext.save()

        // Then
        XCTAssertEqual(webContent.faviconPath, "thumbnails/favicon.png")
        XCTAssertEqual(webContent.ogImageURL, ogImageURL)
        XCTAssertNotNil(webContent.metadataFetchedAt)
    }

    func testBookmarkItemWebContentRelationship() throws {
        // Given
        let url = URL(string: "https://example.com")!
        let item = BookmarkItem(contentType: .article, title: "Test", sourceURL: url)
        let webContent = WebContent(url: url, extractedText: "Content")

        // When
        item.webContent = webContent
        modelContext.insert(item)
        try modelContext.save()

        // Then
        XCTAssertNotNil(item.webContent)
        XCTAssertEqual(item.webContent?.url, url)
    }

    // MARK: - Content Type Tests

    func testContentTypeRequiresMetadataFetch() {
        XCTAssertTrue(ContentType.url.requiresMetadataFetch)
        XCTAssertTrue(ContentType.article.requiresMetadataFetch)
        XCTAssertTrue(ContentType.youtube.requiresMetadataFetch)
        XCTAssertTrue(ContentType.socialPost.requiresMetadataFetch)

        XCTAssertFalse(ContentType.image.requiresMetadataFetch)
        XCTAssertFalse(ContentType.screenshot.requiresMetadataFetch)
        XCTAssertFalse(ContentType.text.requiresMetadataFetch)
        XCTAssertFalse(ContentType.pdf.requiresMetadataFetch)
    }

    // MARK: - URLMetadata Tests

    func testURLMetadataCreation() {
        // Given/When
        let metadata = URLMetadata(
            title: "Test Article",
            description: "A test description",
            siteName: "Example",
            author: "John Doe",
            imageURL: URL(string: "https://example.com/image.jpg"),
            faviconURL: URL(string: "https://example.com/favicon.ico")
        )

        // Then
        XCTAssertEqual(metadata.title, "Test Article")
        XCTAssertEqual(metadata.description, "A test description")
        XCTAssertEqual(metadata.displayTitle, "Test Article")
        XCTAssertNotNil(metadata.thumbnailSourceURL)
    }

    func testURLMetadataDisplayTitleFallback() {
        // Given - no title, but has siteName
        let metadata = URLMetadata(
            title: nil,
            siteName: "Example Site"
        )

        // Then
        XCTAssertEqual(metadata.displayTitle, "Example Site")
    }

    func testURLMetadataMerging() {
        // Given
        let metadata1 = URLMetadata(
            title: "Title 1",
            description: nil,
            imageURL: URL(string: "https://example.com/image1.jpg")
        )
        let metadata2 = URLMetadata(
            title: nil,
            description: "Description 2",
            imageURL: URL(string: "https://example.com/image2.jpg")
        )

        // When
        let merged = metadata1.merging(with: metadata2)

        // Then
        XCTAssertEqual(merged.title, "Title 1") // From metadata1
        XCTAssertEqual(merged.description, "Description 2") // From metadata2
        XCTAssertEqual(merged.imageURL?.absoluteString, "https://example.com/image1.jpg") // From metadata1
    }

    // MARK: - YouTube Tests

    func testYouTubeThumbnailProviderExtractsVideoID() {
        // Standard URL
        let url1 = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
        XCTAssertEqual(YouTubeThumbnailProvider.extractVideoID(from: url1), "dQw4w9WgXcQ")

        // Short URL
        let url2 = URL(string: "https://youtu.be/dQw4w9WgXcQ")!
        XCTAssertEqual(YouTubeThumbnailProvider.extractVideoID(from: url2), "dQw4w9WgXcQ")

        // Embed URL
        let url3 = URL(string: "https://www.youtube.com/embed/dQw4w9WgXcQ")!
        XCTAssertEqual(YouTubeThumbnailProvider.extractVideoID(from: url3), "dQw4w9WgXcQ")

        // Shorts URL
        let url4 = URL(string: "https://www.youtube.com/shorts/dQw4w9WgXcQ")!
        XCTAssertEqual(YouTubeThumbnailProvider.extractVideoID(from: url4), "dQw4w9WgXcQ")
    }

    func testYouTubeThumbnailProviderGeneratesURL() {
        let youtubeURL = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!

        let thumbnailURL = YouTubeThumbnailProvider.thumbnailURL(for: youtubeURL)

        XCTAssertNotNil(thumbnailURL)
        XCTAssertTrue(thumbnailURL!.absoluteString.contains("dQw4w9WgXcQ"))
        XCTAssertTrue(thumbnailURL!.absoluteString.contains("img.youtube.com"))
    }

    func testYouTubeThumbnailProviderIsYouTubeURL() {
        XCTAssertTrue(YouTubeThumbnailProvider.isYouTubeURL(URL(string: "https://youtube.com/watch?v=abc")!))
        XCTAssertTrue(YouTubeThumbnailProvider.isYouTubeURL(URL(string: "https://www.youtube.com/watch?v=abc")!))
        XCTAssertTrue(YouTubeThumbnailProvider.isYouTubeURL(URL(string: "https://youtu.be/abc")!))

        XCTAssertFalse(YouTubeThumbnailProvider.isYouTubeURL(URL(string: "https://example.com")!))
        XCTAssertFalse(YouTubeThumbnailProvider.isYouTubeURL(URL(string: "https://vimeo.com/123")!))
    }

    // MARK: - HTMLMetadataParser Tests

    func testHTMLMetadataParserExtractsOGTags() {
        let html = """
        <html>
        <head>
            <meta property="og:title" content="Test Article Title">
            <meta property="og:description" content="Test description">
            <meta property="og:image" content="https://example.com/image.jpg">
            <meta property="og:site_name" content="Example Site">
        </head>
        </html>
        """
        let baseURL = URL(string: "https://example.com")!

        let metadata = HTMLMetadataParser.parse(html: html, baseURL: baseURL)

        XCTAssertEqual(metadata.title, "Test Article Title")
        XCTAssertEqual(metadata.description, "Test description")
        XCTAssertEqual(metadata.siteName, "Example Site")
        XCTAssertEqual(metadata.imageURL?.absoluteString, "https://example.com/image.jpg")
    }

    func testHTMLMetadataParserExtractsTitleTag() {
        let html = """
        <html>
        <head>
            <title>Page Title</title>
        </head>
        </html>
        """
        let baseURL = URL(string: "https://example.com")!

        let metadata = HTMLMetadataParser.parse(html: html, baseURL: baseURL)

        XCTAssertEqual(metadata.title, "Page Title")
    }

    func testHTMLMetadataParserExtractsFavicon() {
        let html = """
        <html>
        <head>
            <link rel="icon" href="/favicon.ico">
        </head>
        </html>
        """
        let baseURL = URL(string: "https://example.com")!

        let metadata = HTMLMetadataParser.parse(html: html, baseURL: baseURL)

        XCTAssertEqual(metadata.faviconURL?.absoluteString, "https://example.com/favicon.ico")
    }

    func testHTMLMetadataParserHandlesRelativeURLs() {
        let html = """
        <html>
        <head>
            <meta property="og:image" content="/images/og.jpg">
        </head>
        </html>
        """
        let baseURL = URL(string: "https://example.com/page")!

        let metadata = HTMLMetadataParser.parse(html: html, baseURL: baseURL)

        XCTAssertEqual(metadata.imageURL?.absoluteString, "https://example.com/images/og.jpg")
    }

    // MARK: - ImageResizer Tests

    func testImageResizerSizeValues() {
        XCTAssertEqual(ImageResizer.ThumbnailSize.small.width, 88)
        XCTAssertEqual(ImageResizer.ThumbnailSize.medium.width, 160)
        XCTAssertEqual(ImageResizer.ThumbnailSize.large.width, 240)
        XCTAssertEqual(ImageResizer.ThumbnailSize.custom(width: 300).width, 300)
    }

    // MARK: - Processing Status Tests

    func testProcessingStatusTransitions() throws {
        let item = BookmarkItem(contentType: .url, title: "Test")
        modelContext.insert(item)

        // Initial state
        XCTAssertEqual(item.processingStatus, .pending)
        XCTAssertTrue(item.isPending)

        // Transition to processing
        item.processingStatus = .processing
        XCTAssertEqual(item.processingStatus, .processing)
        XCTAssertFalse(item.isPending)
        XCTAssertFalse(item.isProcessed)

        // Transition to completed
        item.processingStatus = .completed
        XCTAssertEqual(item.processingStatus, .completed)
        XCTAssertTrue(item.isProcessed)
        XCTAssertFalse(item.isPending)

        try modelContext.save()
    }

    // MARK: - Query Tests

    func testFetchPendingItems() throws {
        // Given - create items with different statuses
        let pending1 = BookmarkItem(contentType: .url, title: "Pending 1")
        let pending2 = BookmarkItem(contentType: .url, title: "Pending 2")
        let completed = BookmarkItem(contentType: .url, title: "Completed")
        completed.processingStatus = .completed

        modelContext.insert(pending1)
        modelContext.insert(pending2)
        modelContext.insert(completed)
        try modelContext.save()

        // When - fetch pending items
        let descriptor = FetchDescriptor<BookmarkItem>(
            predicate: #Predicate<BookmarkItem> { item in
                item.processingStatusRaw == "pending"
            }
        )
        let pendingItems = try modelContext.fetch(descriptor)

        // Then
        XCTAssertEqual(pendingItems.count, 2)
        XCTAssertTrue(pendingItems.allSatisfy { $0.processingStatus == .pending })
    }
}
