import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var emoji: String             // Actual emoji character (e.g., "🧾")
    var categoryDescription: String  // What this category is used for
    var aiPrompt: String          // Custom AI instructions for this category
    var isDefault: Bool           // Only one category can be default
    var isArchived: Bool          // Hidden but data preserved
    var showInFeed: Bool          // Whether items appear in the resurfacing feed
    var sortOrder: Int            // For manual ordering
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \BookmarkItem.category)
    var items: [BookmarkItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String = "📁",
        description: String = "",
        aiPrompt: String = "",
        isDefault: Bool = false,
        isArchived: Bool = false,
        showInFeed: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.categoryDescription = description
        self.aiPrompt = aiPrompt
        self.isDefault = isDefault
        self.isArchived = isArchived
        self.showInFeed = showInFeed
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}

// MARK: - Computed Properties

extension Category {
    /// Number of non-archived items in this category
    var activeItemCount: Int {
        items.filter { !$0.isArchived }.count
    }

    /// Display string combining emoji and name
    var displayName: String {
        "\(emoji) \(name)"
    }
}

// MARK: - Default Category

extension Category {
    /// Creates the default "Universal Folder" category for new users
    static func createUniversalFolder() -> Category {
        Category(
            name: "Universal Folder",
            emoji: "📁",
            description: "A catch-all for anything you want to save and revisit later.",
            aiPrompt: "Analyze this content and extract the most important information. Identify key topics, actionable items, and any details worth remembering.",
            isDefault: true,
            sortOrder: 0
        )
    }
}
