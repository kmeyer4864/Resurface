import SwiftUI

/// Category filter pill with icon, label, and selection state
struct CategoryPill: View {
    let category: Category
    var isSelected: Bool = false
    var showCount: Bool = false
    var style: PillStyle = .default

    enum PillStyle {
        case `default`  // Full size with icon + label
        case compact    // Small, just icon + name
        case iconOnly   // Just the icon
    }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            // Icon
            Image(systemName: category.icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(iconColor)

            // Label (not shown in iconOnly)
            if style != .iconOnly {
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

    private var categoryColor: Color {
        Color(hex: category.color) ?? ResurfaceTheme.Colors.accent
    }

    private var iconSize: CGFloat {
        switch style {
        case .default: return 12
        case .compact: return 10
        case .iconOnly: return 14
        }
    }

    private var labelFont: Font {
        switch style {
        case .default: return Typography.captionMedium
        case .compact: return Typography.micro
        case .iconOnly: return Typography.micro
        }
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .default: return Spacing.sm
        case .compact: return Spacing.xs
        case .iconOnly: return Spacing.xs
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .default: return Spacing.xs
        case .compact: return Spacing.xxs
        case .iconOnly: return Spacing.xs
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return categoryColor.opacity(0.2)
        }
        return ResurfaceTheme.Colors.surfaceElevatedFallback
    }

    private var borderColor: Color {
        if isSelected {
            return categoryColor
        }
        return ResurfaceTheme.Colors.border
    }

    private var iconColor: Color {
        if isSelected {
            return categoryColor
        }
        return ResurfaceTheme.Colors.textSecondary
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
        Category(name: "Tech", icon: "cpu.fill", color: "#5856D6", isSystem: true),
        Category(name: "Finance", icon: "dollarsign.circle.fill", color: "#34C759", isSystem: true),
        Category(name: "Health", icon: "heart.fill", color: "#FF2D55", isSystem: true),
        Category(name: "Learning", icon: "book.fill", color: "#007AFF", isSystem: true)
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
