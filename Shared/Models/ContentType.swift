import Foundation

/// Types of content that can be saved to Resurface
/// Shared between main app and Share Extension
enum ContentType: String, Codable, CaseIterable, Sendable {
    case url = "url"
    case article = "article"
    case image = "image"
    case screenshot = "screenshot"
    case video = "video"
    case youtube = "youtube"
    case socialPost = "socialPost"
    case text = "text"
    case pdf = "pdf"
    case file = "file"
    case unknown = "unknown"

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .url: return "Link"
        case .article: return "Article"
        case .image: return "Image"
        case .screenshot: return "Screenshot"
        case .video: return "Video"
        case .youtube: return "YouTube"
        case .socialPost: return "Social Post"
        case .text: return "Text"
        case .pdf: return "PDF"
        case .file: return "File"
        case .unknown: return "Unknown"
        }
    }

    /// SF Symbol name for this content type
    var iconName: String {
        switch self {
        case .url: return "link"
        case .article: return "doc.text"
        case .image: return "photo"
        case .screenshot: return "camera.viewfinder"
        case .video: return "video"
        case .youtube: return "play.rectangle"
        case .socialPost: return "bubble.left"
        case .text: return "text.alignleft"
        case .pdf: return "doc.fill"
        case .file: return "doc"
        case .unknown: return "questionmark.circle"
        }
    }
}
