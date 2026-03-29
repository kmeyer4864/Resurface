import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true

    var body: some View {
        NavigationStack {
            List {
                // Categories Section
                Section {
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        Label {
                            Text("Categories")
                                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(ResurfaceTheme.Colors.accent)
                        }
                    }
                } header: {
                    Text("Organization")
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)

                // AI Processing Section
                Section {
                    NavigationLink {
                        AIStatusView()
                    } label: {
                        Label {
                            Text("AI Processing")
                                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                        } icon: {
                            Image(systemName: "sparkles")
                                .foregroundStyle(ResurfaceTheme.Colors.accent)
                        }
                    }
                } header: {
                    Text("AI")
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)

                // Notifications Section
                Section {
                    Toggle(isOn: $enableNotifications) {
                        Label {
                            Text("Resurface Reminders")
                                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                        } icon: {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(ResurfaceTheme.Colors.accent)
                        }
                    }
                    .tint(ResurfaceTheme.Colors.accent)
                } header: {
                    Text("Notifications")
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                } footer: {
                    Text("Get notified when it's time to revisit saved content.")
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)

                // Data Section
                Section {
                    NavigationLink {
                        Text("Export")
                            .navigationTitle("Export Data")
                    } label: {
                        Label {
                            Text("Export Data")
                                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                        } icon: {
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundStyle(ResurfaceTheme.Colors.accent)
                        }
                    }
                } header: {
                    Text("Data")
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)

                // About Section
                Section {
                    HStack {
                        Label {
                            Text("Version")
                                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(ResurfaceTheme.Colors.accent)
                        }
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                    }
                } header: {
                    Text("About")
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
            .navigationTitle("Settings")
            .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - AI Status View

struct AIStatusView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pendingItems: [BookmarkItem]
    @Query private var failedItems: [BookmarkItem]
    @Query private var completedItems: [BookmarkItem]

    @State private var isRetrying = false

    init() {
        let pendingPredicate = #Predicate<BookmarkItem> { $0.aiProcessingStatusRaw == "pending" }
        let failedPredicate = #Predicate<BookmarkItem> { $0.aiProcessingStatusRaw == "failed" }
        let completedPredicate = #Predicate<BookmarkItem> { $0.aiProcessingStatusRaw == "completed" }

        _pendingItems = Query(filter: pendingPredicate)
        _failedItems = Query(filter: failedPredicate)
        _completedItems = Query(filter: completedPredicate)
    }

    var body: some View {
        List {
            // Status Overview
            Section {
                statusRow(label: "Analyzed", count: completedItems.count, icon: "checkmark.circle.fill", color: .green)
                statusRow(label: "Pending", count: pendingItems.count, icon: "clock.fill", color: .orange)
                statusRow(label: "Failed", count: failedItems.count, icon: "exclamationmark.triangle.fill", color: .red)
            } header: {
                Text("Status")
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
            }
            .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)

            // Retry Section
            if !failedItems.isEmpty || !pendingItems.isEmpty {
                Section {
                    Button {
                        retryAIProcessing()
                    } label: {
                        HStack {
                            if isRetrying {
                                ProgressView()
                                    .tint(ResurfaceTheme.Colors.accent)
                                Text("Processing...")
                                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundStyle(ResurfaceTheme.Colors.accent)
                                Text("Retry AI Processing")
                                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                            }
                            Spacer()
                            Text("\(pendingItems.count + failedItems.count) items")
                                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                        }
                    }
                    .disabled(isRetrying)
                } header: {
                    Text("Actions")
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)
            }

            // About AI
            Section {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("AI analyzes your saved content through the lens of each category, extracting relevant information and ignoring the rest.")
                        .font(Typography.subheadline)
                        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)

                    Text("Processing happens automatically when you save new content.")
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .padding(.vertical, Spacing.xs)
            } header: {
                Text("About")
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
            }
            .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
        .navigationTitle("AI Processing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func statusRow(label: String, count: Int, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
            Spacer()
            Text("\(count)")
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
        }
    }

    private func retryAIProcessing() {
        isRetrying = true
        Task {
            await BackgroundProcessor.shared.retryAIProcessing(in: modelContext)
            isRetrying = false
        }
    }
}

// MARK: - Category Management View

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Category> { !$0.isArchived }, sort: \Category.sortOrder)
    private var activeCategories: [Category]

    @Query(filter: #Predicate<Category> { $0.isArchived }, sort: \Category.sortOrder)
    private var archivedCategories: [Category]

    @State private var showCreateCategory = false
    @State private var categoryToEdit: Category?
    @State private var showArchived = false

    var body: some View {
        List {
            // Active Categories
            Section {
                ForEach(activeCategories) { category in
                    CategoryRow(
                        category: category,
                        onEdit: { categoryToEdit = category },
                        onSetDefault: { setAsDefault(category) },
                        onArchive: { archive(category) }
                    )
                }
                .onMove(perform: moveCategories)
                .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)

                // Add new category button
                Button {
                    showCreateCategory = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(ResurfaceTheme.Colors.accent)
                        Text("Create Category")
                            .foregroundStyle(ResurfaceTheme.Colors.accent)
                    }
                }
                .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)
            } header: {
                Text("Categories")
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
            } footer: {
                Text("Drag to reorder. The default category is used when sharing without selecting.")
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
            }

            // Archived Categories
            if !archivedCategories.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: $showArchived) {
                        ForEach(archivedCategories) { category in
                            HStack(spacing: Spacing.sm) {
                                Text(category.emoji)
                                    .font(.system(size: 24))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.name)
                                        .font(Typography.subheadlineMedium)
                                        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)

                                    Text("\(category.items.count) items")
                                        .font(Typography.caption)
                                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                                }

                                Spacer()

                                Button("Restore") {
                                    unarchive(category)
                                }
                                .font(Typography.caption)
                                .foregroundStyle(ResurfaceTheme.Colors.accent)
                            }
                            .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "archivebox")
                                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                            Text("Archived (\(archivedCategories.count))")
                                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                        }
                    }
                }
                .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)
            }
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
                    .foregroundStyle(ResurfaceTheme.Colors.accent)
            }
        }
        .sheet(isPresented: $showCreateCategory) {
            CategoryCreationView()
        }
        .sheet(item: $categoryToEdit) { category in
            CategoryEditView(category: category)
        }
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var categories = activeCategories
        categories.move(fromOffsets: source, toOffset: destination)

        for (index, category) in categories.enumerated() {
            category.sortOrder = index
        }

        try? modelContext.save()
    }

    private func setAsDefault(_ category: Category) {
        CategorySeeder.shared.setDefaultCategory(category, in: modelContext)
    }

    private func archive(_ category: Category) {
        CategorySeeder.shared.archiveCategory(category, in: modelContext)
    }

    private func unarchive(_ category: Category) {
        CategorySeeder.shared.unarchiveCategory(category, in: modelContext)
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: Category
    let onEdit: () -> Void
    let onSetDefault: () -> Void
    let onArchive: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Emoji
            Text(category.emoji)
                .font(.system(size: 28))

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(category.name)
                        .font(Typography.subheadlineMedium)
                        .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                    if category.isDefault {
                        Text("Default")
                            .font(Typography.micro)
                            .foregroundStyle(ResurfaceTheme.Colors.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ResurfaceTheme.Colors.accentSubtle)
                            .clipShape(Capsule())
                    }
                }

                Text("\(category.items.count) items")
                    .font(Typography.caption)
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            if !category.isDefault {
                Button {
                    onSetDefault()
                } label: {
                    Label("Set as Default", systemImage: "star")
                }
            }

            Divider()

            Button(role: .destructive) {
                onArchive()
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
        .preferredColorScheme(.dark)
}
