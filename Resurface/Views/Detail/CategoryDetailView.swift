import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let category: Category

    @State private var viewMode: ViewMode = .grid

    enum ViewMode {
        case list, grid
    }

    var body: some View {
        Group {
            if category.items.isEmpty {
                emptyState
            } else {
                contentView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(Spacing.animation.springFast) {
                        viewMode = viewMode == .list ? .grid : .list
                    }
                } label: {
                    Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Category header
                categoryHeader
                    .padding(.horizontal, Spacing.layout.horizontalPadding)

                // Items
                switch viewMode {
                case .list:
                    listContent
                case .grid:
                    gridContent
                }
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxxl)
        }
    }

    // MARK: - Category Header

    private var categoryHeader: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.color)?.opacity(0.2) ?? ResurfaceTheme.Colors.accentSubtle)
                    .frame(width: 44, height: 44)

                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: category.color) ?? ResurfaceTheme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(Typography.headline)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                Text("\(category.items.count) item\(category.items.count == 1 ? "" : "s")")
                    .font(Typography.caption)
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(ResurfaceTheme.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius.large)
                .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
        )
    }

    // MARK: - List Content

    private var listContent: some View {
        LazyVStack(spacing: Spacing.xs) {
            ForEach(category.items) { item in
                NavigationLink(destination: BookmarkDetailView(item: item)) {
                    BookmarkCardCompact(item: item)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.layout.horizontalPadding)
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
            ForEach(category.items) { item in
                NavigationLink(destination: BookmarkDetailView(item: item)) {
                    BookmarkCard(item: item)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.layout.horizontalPadding)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: category.icon,
            title: "No Items",
            description: "Items in \(category.name) will appear here."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(category: Category(name: "Tech", icon: "cpu.fill", color: "#5856D6"))
    }
    .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
    .preferredColorScheme(.dark)
}
