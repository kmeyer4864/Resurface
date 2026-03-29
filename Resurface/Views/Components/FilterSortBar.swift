import SwiftUI

/// Multi-criteria filter and sort bar for the bookmark list
struct FilterSortBar: View {
    @Binding var selectedCategory: Category?
    @Binding var selectedSource: SourceExtractor.SourceInfo?
    @Binding var sortOption: SortOption
    @Binding var sortAscending: Bool

    let categories: [Category]
    let availableSources: [SourceExtractor.SourceInfo]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // Category filter
                categoryMenu

                // Source filter
                sourceMenu

                // Sort options
                sortMenu

                // Sort direction
                sortDirectionButton
            }
            .padding(.horizontal, Spacing.layout.horizontalPadding)
        }
    }

    // MARK: - Category Menu

    private var categoryMenu: some View {
        Menu {
            Button {
                withAnimation(Spacing.animation.springFast) {
                    selectedCategory = nil
                }
            } label: {
                HStack {
                    Text("All Categories")
                    if selectedCategory == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(categories) { category in
                Button {
                    withAnimation(Spacing.animation.springFast) {
                        selectedCategory = category
                    }
                } label: {
                    HStack {
                        Text("\(category.emoji) \(category.name)")
                        if selectedCategory?.id == category.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            FilterChip(
                icon: selectedCategory != nil ? nil : "folder",
                label: selectedCategory.map { "\($0.emoji) \($0.name)" } ?? "Category",
                isActive: selectedCategory != nil
            )
        }
    }

    // MARK: - Source Menu

    private var sourceMenu: some View {
        Menu {
            Button {
                withAnimation(Spacing.animation.springFast) {
                    selectedSource = nil
                }
            } label: {
                HStack {
                    Text("All Sources")
                    if selectedSource == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(availableSources, id: \.name) { source in
                Button {
                    withAnimation(Spacing.animation.springFast) {
                        selectedSource = source
                    }
                } label: {
                    HStack {
                        Image(systemName: source.icon)
                        Text(source.name)
                        if selectedSource?.name == source.name {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            FilterChip(
                icon: selectedSource?.icon ?? "globe",
                label: selectedSource?.name ?? "Source",
                isActive: selectedSource != nil
            )
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases) { option in
                Button {
                    withAnimation(Spacing.animation.springFast) {
                        sortOption = option
                    }
                } label: {
                    HStack {
                        Image(systemName: option.icon)
                        Text(option.label)
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            FilterChip(
                icon: sortOption.icon,
                label: sortOption.label,
                isActive: false,
                showChevron: true
            )
        }
    }

    // MARK: - Sort Direction Button

    private var sortDirectionButton: some View {
        Button {
            withAnimation(Spacing.animation.springFast) {
                sortAscending.toggle()
            }
        } label: {
            Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                .frame(width: 32, height: 32)
                .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable, Identifiable {
    case date = "date"
    case title = "title"
    case source = "source"
    case category = "category"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .date: return "Date"
        case .title: return "Title"
        case .source: return "Source"
        case .category: return "Category"
        }
    }

    var icon: String {
        switch self {
        case .date: return "calendar"
        case .title: return "textformat"
        case .source: return "globe"
        case .category: return "folder"
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let icon: String?
    let label: String
    var isActive: Bool = false
    var showChevron: Bool = false

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
            }

            Text(label)
                .font(Typography.captionMedium)

            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
        }
        .foregroundStyle(isActive ? ResurfaceTheme.Colors.textPrimary : ResurfaceTheme.Colors.textSecondary)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(isActive ? ResurfaceTheme.Colors.accent.opacity(0.2) : ResurfaceTheme.Colors.surfaceElevatedFallback)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isActive ? ResurfaceTheme.Colors.accent : ResurfaceTheme.Colors.border, lineWidth: isActive ? 1 : 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedCategory: Category? = nil
        @State private var selectedSource: SourceExtractor.SourceInfo? = nil
        @State private var sortOption: SortOption = .date
        @State private var sortAscending = false

        let sampleCategories = [
            Category(name: "Tech", emoji: "💻", description: "Tech"),
            Category(name: "Finance", emoji: "💰", description: "Finance"),
            Category(name: "Health", emoji: "❤️", description: "Health")
        ]

        let sampleSources = [
            SourceExtractor.SourceInfo(name: "Instagram", icon: "camera", color: "#E4405F"),
            SourceExtractor.SourceInfo(name: "YouTube", icon: "play.rectangle", color: "#FF0000"),
            SourceExtractor.SourceInfo(name: "Safari", icon: "safari", color: "#006CFF")
        ]

        var body: some View {
            VStack(spacing: Spacing.lg) {
                FilterSortBar(
                    selectedCategory: $selectedCategory,
                    selectedSource: $selectedSource,
                    sortOption: $sortOption,
                    sortAscending: $sortAscending,
                    categories: sampleCategories,
                    availableSources: sampleSources
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Current State:")
                        .textStyle(.headline)
                    Text("Category: \(selectedCategory?.name ?? "All")")
                        .textStyle(.caption)
                    Text("Source: \(selectedSource?.name ?? "All")")
                        .textStyle(.caption)
                    Text("Sort: \(sortOption.label) \(sortAscending ? "↑" : "↓")")
                        .textStyle(.caption)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ResurfaceTheme.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, Spacing.lg)
            .background(ResurfaceTheme.Colors.backgroundFallback)
        }
    }

    return PreviewWrapper()
}
