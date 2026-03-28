import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [BookmarkItem]
    @Query private var categories: [Category]

    @State private var searchText = ""
    @State private var isSearching = false

    private var searchResults: [BookmarkItem] {
        guard !searchText.isEmpty else { return [] }
        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(searchText) ||
            (item.rawText?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            item.tags.contains { $0.name.localizedCaseInsensitiveContains(searchText) } ||
            (item.category?.name.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // Group results by content type for better organization
    private var groupedResults: [(ContentType, [BookmarkItem])] {
        let grouped = Dictionary(grouping: searchResults) { $0.contentType }
        return grouped.sorted { $0.value.count > $1.value.count }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if searchText.isEmpty {
                        idleState
                    } else if searchResults.isEmpty {
                        noResultsState
                    } else {
                        resultsContent
                    }
                }
                .padding(.bottom, Spacing.xxxl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, isPresented: $isSearching, prompt: "Search all content")
            .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Idle State

    private var idleState: some View {
        VStack(spacing: Spacing.lg) {
            // Search prompt
            VStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)

                Text("Search Your Collection")
                    .font(Typography.title3)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                Text("Find bookmarks by title, content, tags, or category")
                    .font(Typography.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Spacing.xxxl)

            // Quick filters (categories)
            if !categories.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Browse by Category")
                        .font(Typography.captionMedium)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                        .padding(.horizontal, Spacing.layout.horizontalPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(categories.filter { !$0.items.isEmpty }) { category in
                                Button {
                                    searchText = category.name
                                } label: {
                                    CategoryPill(category: category, showCount: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Spacing.layout.horizontalPadding)
                    }
                }
                .padding(.top, Spacing.xl)
            }
        }
    }

    // MARK: - Results Content

    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Results count
            Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                .font(Typography.captionMedium)
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                .padding(.horizontal, Spacing.layout.horizontalPadding)
                .padding(.top, Spacing.sm)

            // Results grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Spacing.layout.gridGap),
                    GridItem(.flexible(), spacing: Spacing.layout.gridGap)
                ],
                spacing: Spacing.layout.gridGap
            ) {
                ForEach(searchResults) { item in
                    NavigationLink(destination: BookmarkDetailView(item: item)) {
                        BookmarkCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.layout.horizontalPadding)
        }
    }

    // MARK: - No Results State

    private var noResultsState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)

            VStack(spacing: Spacing.xs) {
                Text("No Results Found")
                    .font(Typography.title3)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                Text("Try a different search term")
                    .font(Typography.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
            }
        }
        .padding(.top, Spacing.xxxl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
        .preferredColorScheme(.dark)
}
