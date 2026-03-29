import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BookmarkItem.createdAt, order: .reverse)
    private var allItems: [BookmarkItem]

    @Query(sort: \Category.name)
    private var categories: [Category]

    // Filter state
    @State private var selectedCategory: Category?
    @State private var selectedSource: SourceExtractor.SourceInfo?
    @State private var sortOption: SortOption = .date
    @State private var sortAscending = false

    // Search state
    @State private var searchText = ""
    @State private var isSearching = false

    // Remind sheet state
    @State private var itemToRemind: BookmarkItem?
    @State private var showRemindSheet = false

    // Non-archived items only
    private var activeItems: [BookmarkItem] {
        allItems.filter { !$0.isArchived }
    }

    // Available sources for filter
    private var availableSources: [SourceExtractor.SourceInfo] {
        SourceExtractor.uniqueSources(from: activeItems)
    }

    // Filtered and sorted items
    private var filteredItems: [BookmarkItem] {
        var items = activeItems

        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                (item.rawText?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.category?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply category filter
        if let category = selectedCategory {
            items = items.filter { $0.category?.id == category.id }
        }

        // Apply source filter
        if let source = selectedSource {
            items = items.filter { item in
                let itemSource = SourceExtractor.bestSource(url: item.sourceURL, sourceApp: item.sourceApp)
                return itemSource.name == source.name
            }
        }

        // Apply sorting
        items = sortItems(items)

        return items
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter/Sort bar
                if !categories.isEmpty || !availableSources.isEmpty {
                    FilterSortBar(
                        selectedCategory: $selectedCategory,
                        selectedSource: $selectedSource,
                        sortOption: $sortOption,
                        sortAscending: $sortAscending,
                        categories: categories.filter { !$0.isArchived },
                        availableSources: availableSources
                    )
                    .padding(.vertical, Spacing.sm)
                }

                // Content
                if activeItems.isEmpty {
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredItems.isEmpty {
                    noResultsView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    bookmarkList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
            .navigationTitle("Resurface")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search bookmarks")
            .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showRemindSheet) {
                if let item = itemToRemind {
                    RemindSheet(item: item)
                        .presentationDetents([.medium])
                }
            }
        }
    }

    // MARK: - Bookmark List

    private var bookmarkList: some View {
        List {
            ForEach(filteredItems) { item in
                NavigationLink(destination: BookmarkDetailView(item: item)) {
                    BookmarkRowContent(item: item)
                }
                .listRowBackground(ResurfaceTheme.Colors.backgroundFallback)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        archiveItem(item)
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(ResurfaceTheme.Colors.warning)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        toggleFavorite(item)
                    } label: {
                        Label(
                            item.isFavorite ? "Unfavorite" : "Favorite",
                            systemImage: item.isFavorite ? "star.slash" : "star.fill"
                        )
                    }
                    .tint(.yellow)

                    Button {
                        itemToRemind = item
                        showRemindSheet = true
                    } label: {
                        Label("Remind", systemImage: "bell")
                    }
                    .tint(ResurfaceTheme.Colors.accent)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Sorting

    private func sortItems(_ items: [BookmarkItem]) -> [BookmarkItem] {
        let sorted: [BookmarkItem]

        switch sortOption {
        case .date:
            sorted = items.sorted { sortAscending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt }
        case .title:
            sorted = items.sorted { sortAscending ? $0.displayTitle < $1.displayTitle : $0.displayTitle > $1.displayTitle }
        case .source:
            sorted = items.sorted {
                let source1 = SourceExtractor.bestSource(url: $0.sourceURL, sourceApp: $0.sourceApp).name
                let source2 = SourceExtractor.bestSource(url: $1.sourceURL, sourceApp: $1.sourceApp).name
                return sortAscending ? source1 < source2 : source1 > source2
            }
        case .category:
            sorted = items.sorted {
                let cat1 = $0.category?.name ?? ""
                let cat2 = $1.category?.name ?? ""
                return sortAscending ? cat1 < cat2 : cat1 > cat2
            }
        }

        return sorted
    }

    // MARK: - Actions

    private func toggleFavorite(_ item: BookmarkItem) {
        withAnimation {
            item.isFavorite.toggle()
            item.markUpdated()
        }
    }

    private func archiveItem(_ item: BookmarkItem) {
        withAnimation {
            item.isArchived = true
            item.markUpdated()
        }
    }

    private func deleteItem(_ item: BookmarkItem) {
        withAnimation {
            modelContext.delete(item)
        }
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "square.stack.3d.up",
            title: "Nothing Saved Yet",
            description: "Share content from any app using the share button to save it here.",
            actionTitle: nil
        )
    }

    private var noResultsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)

            VStack(spacing: Spacing.xs) {
                Text("No Results")
                    .font(Typography.title3)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                Text(noResultsDescription)
                    .font(Typography.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private var noResultsDescription: String {
        if !searchText.isEmpty {
            return "No bookmarks match \"\(searchText)\""
        } else if selectedCategory != nil || selectedSource != nil {
            return "No bookmarks match the current filters"
        }
        return "No bookmarks found"
    }
}

// MARK: - Bookmark Row Content (without swipe, used inside List)

private struct BookmarkRowContent: View {
    let item: BookmarkItem

    private var sourceInfo: SourceExtractor.SourceInfo {
        SourceExtractor.bestSource(url: item.sourceURL, sourceApp: item.sourceApp)
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Thumbnail
            ThumbnailView(
                contentType: item.contentType,
                categoryColor: nil,
                size: .small,
                thumbnailPath: item.thumbnailPath
            )

            // Main content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Title
                Text(item.displayTitle)
                    .font(Typography.subheadlineMedium)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Metadata row
                HStack(spacing: Spacing.xs) {
                    // Category pill (compact)
                    if let category = item.category {
                        HStack(spacing: 2) {
                            Text(category.emoji)
                                .font(.system(size: 10))
                            Text(category.name)
                                .font(Typography.micro)
                                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
                        .clipShape(Capsule())
                    }

                    // Source
                    HStack(spacing: 2) {
                        Image(systemName: sourceInfo.icon)
                            .font(.system(size: 9))
                        Text(sourceInfo.name)
                            .font(Typography.micro)
                    }
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)

                    // Separator
                    Circle()
                        .fill(ResurfaceTheme.Colors.textTertiary)
                        .frame(width: 2, height: 2)

                    // Date
                    Text(item.createdAt, style: .relative)
                        .font(Typography.micro)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
            }

            Spacer(minLength: Spacing.xs)

            // Right indicators
            HStack(spacing: Spacing.xs) {
                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                }

                if item.isResurfacePending {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(ResurfaceTheme.Colors.accent)
                }

                processingIndicator
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.layout.horizontalPadding)
    }

    @ViewBuilder
    private var processingIndicator: some View {
        if item.isPending {
            Image(systemName: "clock")
                .font(.system(size: 11))
                .foregroundStyle(ResurfaceTheme.Colors.warning)
        } else if item.aiProcessingStatus == .processing {
            Image(systemName: "sparkles")
                .font(.system(size: 11))
                .foregroundStyle(ResurfaceTheme.Colors.accent)
                .symbolEffect(.pulse.byLayer)
        } else if item.aiProcessingStatus == .failed {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 11))
                .foregroundStyle(ResurfaceTheme.Colors.error)
        }
    }
}

// MARK: - Remind Sheet

private struct RemindSheet: View {
    let item: BookmarkItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Text("When do you want to be reminded?")
                    .font(Typography.headline)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                    .padding(.top, Spacing.lg)

                VStack(spacing: Spacing.sm) {
                    remindButton("In 1 hour", timeInterval: 3600)
                    remindButton("Tomorrow morning", date: tomorrowMorning)
                    remindButton("This weekend", date: thisWeekend)
                    remindButton("Next week", date: nextWeek)
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(ResurfaceTheme.Colors.backgroundFallback)
            .navigationTitle("Remind Me")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
        }
    }

    private func remindButton(_ title: String, timeInterval: TimeInterval? = nil, date: Date? = nil) -> some View {
        Button {
            let remindDate = date ?? Date().addingTimeInterval(timeInterval ?? 0)
            scheduleReminder(at: remindDate)
            dismiss()
        } label: {
            Text(title)
                .font(Typography.bodyMedium)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
        }
    }

    private func scheduleReminder(at date: Date) {
        item.resurfaceAt = date
        Task {
            let notificationId = await ResurfaceNotificationService.shared.scheduleNotification(
                for: item.id,
                title: item.displayTitle,
                at: date
            )
            await MainActor.run {
                item.resurfaceNotificationId = notificationId
                item.markUpdated()
                try? modelContext.save()
            }
        }
    }

    private var tomorrowMorning: Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
    }

    private var thisWeekend: Date {
        let today = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let saturday = calendar.date(byAdding: .day, value: daysUntilSaturday == 0 ? 7 : daysUntilSaturday, to: today)!
        return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: saturday)!
    }

    private var nextWeek: Date {
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: nextWeek)!
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
        .preferredColorScheme(.dark)
}
