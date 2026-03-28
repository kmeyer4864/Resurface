import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkItem.createdAt, order: .reverse)
    private var items: [BookmarkItem]

    @State private var searchText = ""
    @State private var viewMode: ViewMode = .list
    @AppStorage("libraryViewMode") private var savedViewMode: String = "list"

    enum ViewMode: String {
        case list, grid
    }

    private var filteredItems: [BookmarkItem] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(searchText) ||
            (item.rawText?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else if filteredItems.isEmpty {
                    noResultsState
                } else {
                    contentView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search bookmarks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    viewModeToggle
                }
            }
            .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                viewMode = ViewMode(rawValue: savedViewMode) ?? .list
            }
        }
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        Button {
            withAnimation(Spacing.animation.springFast) {
                viewMode = viewMode == .list ? .grid : .list
                savedViewMode = viewMode.rawValue
            }
        } label: {
            Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            switch viewMode {
            case .list:
                listContent
            case .grid:
                gridContent
            }
        }
    }

    // MARK: - List Content

    private var listContent: some View {
        LazyVStack(spacing: Spacing.xs) {
            ForEach(filteredItems) { item in
                NavigationLink(destination: BookmarkDetailView(item: item)) {
                    BookmarkCardCompact(item: item)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    itemContextMenu(item)
                }
            }
        }
        .padding(.horizontal, Spacing.layout.horizontalPadding)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xxxl)
    }

    // MARK: - Grid Content

    private var gridContent: some View {
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
                .contextMenu {
                    itemContextMenu(item)
                }
            }
        }
        .padding(.horizontal, Spacing.layout.horizontalPadding)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xxxl)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func itemContextMenu(_ item: BookmarkItem) -> some View {
        Button {
            withAnimation {
                item.isFavorite.toggle()
            }
        } label: {
            Label(
                item.isFavorite ? "Remove Favorite" : "Add to Favorites",
                systemImage: item.isFavorite ? "star.slash" : "star"
            )
        }

        Button {
            withAnimation {
                item.isArchived.toggle()
            }
        } label: {
            Label(
                item.isArchived ? "Unarchive" : "Archive",
                systemImage: item.isArchived ? "tray.and.arrow.up" : "archivebox"
            )
        }

        Divider()

        Button(role: .destructive) {
            withAnimation {
                modelContext.delete(item)
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
        EmptyStateView(
            icon: "bookmark",
            title: "No Bookmarks",
            description: "Items you save will appear here."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)

            VStack(spacing: Spacing.xs) {
                Text("No Results")
                    .font(Typography.title3)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                Text("No bookmarks match \"\(searchText)\"")
                    .font(Typography.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
        .preferredColorScheme(.dark)
}
