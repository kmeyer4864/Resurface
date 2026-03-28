import Foundation

/// Status of AI processing for a bookmark item
enum ProcessingStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }
}
