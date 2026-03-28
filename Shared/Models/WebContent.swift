import Foundation
import SwiftData

@Model
final class WebContent {
    var id: UUID
    var url: URL
    var extractedText: String
    var author: String?
    var publishDate: Date?
    var siteName: String?

    // Metadata fields (Phase 1 completion)
    var faviconPath: String?
    var ogImageURL: URL?
    var metadataFetchedAt: Date?

    @Relationship(deleteRule: .nullify)
    var item: BookmarkItem?

    init(
        id: UUID = UUID(),
        url: URL,
        extractedText: String = "",
        author: String? = nil,
        publishDate: Date? = nil,
        siteName: String? = nil,
        faviconPath: String? = nil,
        ogImageURL: URL? = nil,
        metadataFetchedAt: Date? = nil
    ) {
        self.id = id
        self.url = url
        self.extractedText = extractedText
        self.author = author
        self.publishDate = publishDate
        self.siteName = siteName
        self.faviconPath = faviconPath
        self.ogImageURL = ogImageURL
        self.metadataFetchedAt = metadataFetchedAt
    }
}
