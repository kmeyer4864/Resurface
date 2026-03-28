import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BookmarkItem.createdAt, order: .reverse)
    private var allItems: [BookmarkItem]

    @Query(sort: \Category.name)
    private var categories: [Category]

    @State private var selectedCategory: Category?

    // Filtered items based on selected category
    private var filteredItems: [BookmarkItem] {
        guard let category = selectedCategory else {
            return allItems
        }
        return allItems.filter { $0.category?.id == category.id }
    }

    // Categories that have items
    private var categoriesWithItems: [Category] {
        categories.filter { !$0.items.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header section
                    headerSection
                        .padding(.horizontal, Spacing.layout.horizontalPadding)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.lg)

                    // Category filter bar
                    if !categories.isEmpty {
                        categoryFilterBar
                            .padding(.bottom, Spacing.lg)
                    }

                    // Content
                    if allItems.isEmpty {
                        emptyStateView
                            .padding(.top, Spacing.xxxl)
                    } else if filteredItems.isEmpty {
                        // No items in selected category
                        EmptyStateView(
                            icon: "folder",
                            title: "No Items",
                            description: "No bookmarks in this category yet."
                        )
                        .padding(.top, Spacing.xxl)
                    } else {
                        // Main content
                        contentSection
                    }
                }
                .padding(.bottom, Spacing.xxxl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Resurface")
                        .font(Typography.headline)
                        .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                }
            }
            .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        GreetingHeader(itemCount: allItems.count)
    }

    // MARK: - Category Filter Bar

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // "All" filter
                FilterPill(
                    title: "All",
                    icon: nil,
                    isSelected: selectedCategory == nil,
                    count: allItems.count
                )
                .onTapGesture {
                    withAnimation(Spacing.animation.springFast) {
                        selectedCategory = nil
                    }
                }

                // Favorites filter
                let favoriteCount = allItems.filter { $0.isFavorite }.count
                if favoriteCount > 0 {
                    FilterPill(
                        title: "Favorites",
                        icon: "star.fill",
                        isSelected: false,
                        count: favoriteCount
                    )
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

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(spacing: Spacing.layout.sectionGap) {
            // Recent section (grid)
            if selectedCategory == nil {
                recentSection
            }

            // Category sections (horizontal scroll) - only when showing all
            if selectedCategory == nil {
                ForEach(categoriesWithItems.prefix(5)) { category in
                    categorySection(category)
                }
            }

            // Filtered grid (when category selected)
            if selectedCategory != nil {
                filteredGridSection
            }
        }
    }

    // MARK: - Recent Section (Grid)

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Recent")
                .padding(.horizontal, Spacing.layout.horizontalPadding)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Spacing.layout.gridGap),
                    GridItem(.flexible(), spacing: Spacing.layout.gridGap)
                ],
                spacing: Spacing.layout.gridGap
            ) {
                ForEach(filteredItems.prefix(6)) { item in
                    NavigationLink(destination: BookmarkDetailView(item: item)) {
                        BookmarkCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.layout.horizontalPadding)
        }
    }

    // MARK: - Category Section (Horizontal Scroll)

    private func categorySection(_ category: Category) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(
                title: category.name,
                icon: category.icon,
                iconColor: Color(hex: category.color),
                showSeeAll: category.items.count > 4
            ) {
                // Navigate to category detail
                selectedCategory = category
            }
            .padding(.horizontal, Spacing.layout.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(category.items.prefix(8)) { item in
                        NavigationLink(destination: BookmarkDetailView(item: item)) {
                            BookmarkCard(item: item, style: .horizontal)
                                .frame(width: 180)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.layout.horizontalPadding)
            }
        }
    }

    // MARK: - Filtered Grid Section

    private var filteredGridSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let category = selectedCategory {
                SectionHeader(
                    title: category.name,
                    subtitle: "\(filteredItems.count) items",
                    icon: category.icon,
                    iconColor: Color(hex: category.color)
                )
                .padding(.horizontal, Spacing.layout.horizontalPadding)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Spacing.layout.gridGap),
                    GridItem(.flexible(), spacing: Spacing.layout.gridGap)
                ],
                spacing: Spacing.layout.gridGap
            ) {
                ForEach(filteredItems) { item in
                    NavigationLink(destination: BookmarkDetailView(item: item)) {
                        BookmarkCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.layout.horizontalPadding)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "square.stack.3d.up",
            title: "Nothing Saved Yet",
            description: "Share content from any app using the share button to save it here.",
            actionTitle: nil
        )
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
        .preferredColorScheme(.dark)
}
