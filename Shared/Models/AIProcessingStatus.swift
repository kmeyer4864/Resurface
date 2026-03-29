import Foundation

/// Status of AI processing for a bookmark item
/// Separate from ProcessingStatus to allow independent tracking
enum AIProcessingStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case skipped = "skipped"  // e.g., no network, content too short

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Analyzing"
        case .completed: return "Analyzed"
        case .failed: return "Failed"
        case .skipped: return "Skipped"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "sparkles"
        case .completed: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        case .skipped: return "minus.circle"
        }
    }
}
