import Foundation
import SwiftData

/// Seeds the default category on first app launch and handles migrations
actor CategorySeeder {
    /// Shared instance
    static let shared = CategorySeeder()

    /// UserDefaults key for tracking category system version
    private let categoryVersionKey = "categorySystemVersion"

    /// Current category system version (increment when schema changes)
    private let currentVersion = 2

    private init() {}

    /// Seed categories if needed (first launch or migration)
    @MainActor
    func seedCategoriesIfNeeded(in context: ModelContext) {
        let storedVersion = UserDefaults.standard.integer(forKey: categoryVersionKey)

        if storedVersion < currentVersion {
            // Migration needed - clear old categories and start fresh
            migrateToNewCategorySystem(in: context)
            UserDefaults.standard.set(currentVersion, forKey: categoryVersionKey)
        } else {
            // Check if we need to create initial category
            ensureDefaultCategoryExists(in: context)
        }
    }

    /// Migrate from old category system (predefined system categories) to new user-defined system
    @MainActor
    private func migrateToNewCategorySystem(in context: ModelContext) {
        // Delete all existing categories
        let descriptor = FetchDescriptor<Category>()
        if let existingCategories = try? context.fetch(descriptor) {
            for category in existingCategories {
                // Clear category reference from items first
                for item in category.items {
                    item.category = nil
                }
                context.delete(category)
            }
        }

        // Create the Universal Folder as the only default category
        let universalFolder = Category.createUniversalFolder()
        context.insert(universalFolder)

        try? context.save()
    }

    /// Ensure at least one default category exists
    @MainActor
    private func ensureDefaultCategoryExists(in context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        guard let categories = try? context.fetch(descriptor) else { return }

        if categories.isEmpty {
            // No categories exist, create Universal Folder
            let universalFolder = Category.createUniversalFolder()
            context.insert(universalFolder)
            try? context.save()
        } else if !categories.contains(where: { $0.isDefault }) {
            // No default set, make the first non-archived one default
            if let firstActive = categories.first(where: { !$0.isArchived }) {
                firstActive.isDefault = true
                try? context.save()
            }
        }
    }

    /// Set a category as the default (unsets previous default)
    @MainActor
    func setDefaultCategory(_ category: Category, in context: ModelContext) {
        // Unset current default
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.isDefault == true }
        )
        if let currentDefaults = try? context.fetch(descriptor) {
            for cat in currentDefaults {
                cat.isDefault = false
            }
        }

        // Set new default
        category.isDefault = true
        try? context.save()
    }

    /// Archive a category (items remain but category is hidden)
    @MainActor
    func archiveCategory(_ category: Category, in context: ModelContext) {
        category.isArchived = true

        // If this was the default, assign a new default
        if category.isDefault {
            category.isDefault = false

            let descriptor = FetchDescriptor<Category>(
                predicate: #Predicate<Category> { $0.isArchived == false }
            )
            if let activeCategories = try? context.fetch(descriptor),
               let newDefault = activeCategories.first {
                newDefault.isDefault = true
            }
        }

        try? context.save()
    }

    /// Unarchive a category
    @MainActor
    func unarchiveCategory(_ category: Category, in context: ModelContext) {
        category.isArchived = false
        try? context.save()
    }

    /// Create a category from a template
    @MainActor
    func createTemplateCategory(
        _ template: CategoryTemplates.Template,
        sortOrder: Int,
        in context: ModelContext
    ) -> Category {
        let category = Category(
            name: template.name,
            emoji: template.emoji,
            description: template.description,
            aiPrompt: template.aiPrompt,
            sortOrder: sortOrder
        )
        context.insert(category)
        try? context.save()
        return category
    }

    /// Check if a category with the given name already exists (case-insensitive)
    @MainActor
    func categoryExists(named name: String, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Category>()
        guard let categories = try? context.fetch(descriptor) else { return false }
        let lowered = name.lowercased()
        return categories.contains { $0.name.lowercased() == lowered }
    }

    /// Whether the app should suggest categories (Universal Folder has ≥10 items)
    @MainActor
    func shouldSuggestCategories(in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.isDefault == true }
        )
        guard let defaults = try? context.fetch(descriptor),
              let universal = defaults.first else {
            return false
        }
        return universal.activeItemCount >= 10
    }

    /// Delete a category and optionally move items to another category
    @MainActor
    func deleteCategory(_ category: Category, movingItemsTo target: Category?, in context: ModelContext) {
        // Move items if target specified
        if let target = target {
            for item in category.items {
                item.category = target
            }
        } else {
            // Clear category from items
            for item in category.items {
                item.category = nil
            }
        }

        // Handle default reassignment
        if category.isDefault {
            let descriptor = FetchDescriptor<Category>(
                predicate: #Predicate<Category> { $0.isArchived == false }
            )
            if let activeCategories = try? context.fetch(descriptor),
               let newDefault = activeCategories.first(where: { $0.id != category.id }) {
                newDefault.isDefault = true
            }
        }

        context.delete(category)
        try? context.save()
    }
}
