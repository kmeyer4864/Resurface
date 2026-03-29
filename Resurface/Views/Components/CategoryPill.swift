import SwiftUI

/// Category filter pill with emoji, label, and selection state
struct CategoryPill: View {
    let category: Category
    var isSelected: Bool = false
    var showCount: Bool = false
    var style: PillStyle = .default

    enum PillStyle {
        case `default`  // Full size with emoji + label
        case compact    // Small, just emoji + name
        case emojiOnly  // Just the emoji
    }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            // Emoji
            Text(category.emoji)
                .font(.system(size: emojiSize))

            // Label (not shown in emojiOnly)
            if style != .emojiOnly {
                Text(category.name)
                    .font(labelFont)
                    .foregroundStyle(labelColor)
            }

            // Count badge
            if showCount && category.items.count > 0 {
                Text("\(category.items.count)")
                    .font(Typography.micro)
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(borderColor, lineWidth: isSelected ? 1.5 : 0.5)
        )
    }

    // MARK: - Computed Properties

    private var emojiSize: CGFloat {
        switch style {
        case .default: return 14
        case .compact: return 12
        case .emojiOnly: return 16
        }
    }

    private var labelFont: Font {
        switch style {
        case .default: return Typography.captionMedium
        case .compact: return Typography.micro
        case .emojiOnly: return Typography.micro
        }
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .default: return Spacing.sm
        case .compact: return Spacing.xs
        case .emojiOnly: return Spacing.xs
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .default: return Spacing.xs
        case .compact: return Spacing.xxs
        case .emojiOnly: return Spacing.xs
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return ResurfaceTheme.Colors.accent.opacity(0.2)
        }
        return ResurfaceTheme.Colors.surfaceElevatedFallback
    }

    private var borderColor: Color {
        if isSelected {
            return ResurfaceTheme.Colors.accent
        }
        return ResurfaceTheme.Colors.border
    }

    private var labelColor: Color {
        if isSelected {
            return ResurfaceTheme.Colors.textPrimary
        }
        return ResurfaceTheme.Colors.textSecondary
    }
}

// MARK: - Filter Pill (for "All", "Favorites", etc.)

struct FilterPill: View {
    let title: String
    let icon: String?
    var isSelected: Bool = false
    var count: Int? = nil

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
            }

            Text(title)
                .font(Typography.captionMedium)

            if let count = count, count > 0 {
                Text("\(count)")
                    .font(Typography.micro)
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
            }
        }
        .foregroundStyle(isSelected ? ResurfaceTheme.Colors.textPrimary : ResurfaceTheme.Colors.textSecondary)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(isSelected ? ResurfaceTheme.Colors.accent.opacity(0.2) : ResurfaceTheme.Colors.surfaceElevatedFallback)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isSelected ? ResurfaceTheme.Colors.accent : ResurfaceTheme.Colors.border, lineWidth: isSelected ? 1.5 : 0.5)
        )
    }
}

// MARK: - Category Scroll Bar

struct CategoryScrollBar: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    var showAll: Bool = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // "All" filter
                if showAll {
                    FilterPill(
                        title: "All",
                        icon: nil,
                        isSelected: selectedCategory == nil
                    )
                    .onTapGesture {
                        withAnimation(Spacing.animation.springFast) {
                            selectedCategory = nil
                        }
                    }
                }

                // Category pills
                ForEach(categories) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory?.id == category.id,
                        showCount: true
                    )
                    .onTapGesture {
                        withAnimation(Spacing.animation.springFast) {
                            if selectedCategory?.id == category.id {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.layout.horizontalPadding)
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleCategories: [Category] = [
        Category(name: "Tech", emoji: "💻", description: "Technology content"),
        Category(name: "Finance", emoji: "💰", description: "Financial content"),
        Category(name: "Health", emoji: "❤️", description: "Health content"),
        Category(name: "Learning", emoji: "📚", description: "Educational content")
    ]

    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Default Pills")
                .textStyle(.headline)

            HStack(spacing: Spacing.xs) {
                CategoryPill(category: sampleCategories[0])
                CategoryPill(category: sampleCategories[1], isSelected: true)
                CategoryPill(category: sampleCategories[2], showCount: true)
            }

            Text("Compact Pills")
                .textStyle(.headline)
                .padding(.top, Spacing.md)

            HStack(spacing: Spacing.xs) {
                CategoryPill(category: sampleCategories[0], style: .compact)
                CategoryPill(category: sampleCategories[1], isSelected: true, style: .compact)
            }

            Text("Filter Pills")
                .textStyle(.headline)
                .padding(.top, Spacing.md)

            HStack(spacing: Spacing.xs) {
                FilterPill(title: "All", icon: nil, isSelected: true)
                FilterPill(title: "Favorites", icon: "star.fill", count: 12)
                FilterPill(title: "Unread", icon: "clock")
            }

            Text("Category Scroll Bar")
                .textStyle(.headline)
                .padding(.top, Spacing.md)
        }
        .padding()
    }
    .background(ResurfaceTheme.Colors.backgroundFallback)
}
