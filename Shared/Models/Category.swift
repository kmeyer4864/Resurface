import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String              // SF Symbol
    var color: String             // Hex color
    var isSystem: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \BookmarkItem.category)
    var items: [BookmarkItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder",
        color: String = "#007AFF",
        isSystem: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.isSystem = isSystem
        self.createdAt = Date()
    }
}

// MARK: - System Categories

extension Category {
    static let systemCategories: [(name: String, icon: String, color: String)] = [
        ("Health", "heart.fill", "#FF2D55"),
        ("Finance", "dollarsign.circle.fill", "#34C759"),
        ("Tech", "cpu.fill", "#5856D6"),
        ("Career", "briefcase.fill", "#FF9500"),
        ("Learning", "book.fill", "#007AFF"),
        ("Entertainment", "tv.fill", "#AF52DE"),
        ("Shopping", "cart.fill", "#FF3B30"),
        ("Travel", "airplane", "#00C7BE"),
        ("Food", "fork.knife", "#FFCC00"),
        ("News", "newspaper.fill", "#8E8E93")
    ]
}
