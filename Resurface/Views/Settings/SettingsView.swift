import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true

    var body: some View {
        NavigationStack {
            List {
                // General Section
                Section {
                    Toggle(isOn: $enableNotifications) {
                        Label {
                            Text("Notifications")
                                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                        } icon: {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(ResurfaceTheme.Colors.accent)
                        }
                    }
                    .tint(ResurfaceTheme.Colors.accent)
                } header: {
                    Text("General")
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)

                // AI Processing Section
                Section {
                    NavigationLink {
                        APISettingsView()
                    } label: {
                        Label {
                            Text("API Configuration")
                                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                        } icon: {
                            Image(systemName: "brain")
                                .foregroundStyle(ResurfaceTheme.Colors.accent)
                        }
                    }
                } header: {
                    Text("AI Processing")
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)

                // Data Section
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

// MARK: - API Settings View

struct APISettingsView: View {
    @AppStorage("claudeAPIKey") private var apiKey = ""

    var body: some View {
        List {
            Section {
                SecureField("Claude API Key", text: $apiKey)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
            } footer: {
                Text("Your API key is stored securely on device and is used for AI-powered categorization and insights.")
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
            }
            .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
        .navigationTitle("API Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Category Management View

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]

    var body: some View {
        List {
            ForEach(categories) { category in
                HStack(spacing: Spacing.sm) {
                    // Icon with color
                    ZStack {
                        Circle()
                            .fill(Color(hex: category.color)?.opacity(0.2) ?? ResurfaceTheme.Colors.accentSubtle)
                            .frame(width: 36, height: 36)

                        Image(systemName: category.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: category.color) ?? ResurfaceTheme.Colors.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(Typography.subheadlineMedium)
                            .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                        Text("\(category.items.count) items")
                            .font(Typography.caption)
                            .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                    }

                    Spacer()

                    if category.isSystem {
                        Text("System")
                            .font(Typography.micro)
                            .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, Spacing.xxs)
            }
            .onDelete(perform: deleteCategories)
            .listRowBackground(ResurfaceTheme.Colors.surfaceFallback)
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
                Button {
                    // Add category action
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(ResurfaceTheme.Colors.accent)
                }
            }
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            if !category.isSystem {
                modelContext.delete(category)
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
        .preferredColorScheme(.dark)
}
