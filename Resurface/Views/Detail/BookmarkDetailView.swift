import SwiftUI
import SwiftData

struct BookmarkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: BookmarkItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Hero thumbnail
                heroSection

                // Content
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    headerSection
                    metadataSection

                    if !item.keyInsights.isEmpty {
                        insightsSection
                    }

                    if !item.tags.isEmpty {
                        tagsSection
                    }

                    if let rawText = item.rawText, !rawText.isEmpty {
                        contentSection(rawText)
                    }
                }
                .padding(.horizontal, Spacing.layout.horizontalPadding)
            }
            .padding(.bottom, Spacing.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        withAnimation {
                            item.isFavorite.toggle()
                        }
                    } label: {
                        Label(
                            item.isFavorite ? "Remove from Favorites" : "Add to Favorites",
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

                    if let url = item.sourceURL {
                        Divider()
                        ShareLink(item: url)

                        Link(destination: url) {
                            Label("Open in Browser", systemImage: "safari")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        modelContext.delete(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Large thumbnail
            ThumbnailView(
                contentType: item.contentType,
                categoryColor: item.category?.color,
                size: .large
            )
            .frame(height: 200)

            // Gradient overlay
            LinearGradient(
                colors: [
                    .clear,
                    ResurfaceTheme.Colors.backgroundFallback.opacity(0.8),
                    ResurfaceTheme.Colors.backgroundFallback
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content type badge
            ContentTypeBadge(contentType: item.contentType)
                .padding(Spacing.md)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Favorite indicator
            if item.isFavorite {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                    Text("Favorite")
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                }
            }

            // Title
            Text(item.displayTitle)
                .font(Typography.title2)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Source link
            if let url = item.sourceURL {
                Link(destination: url) {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                        Text(url.host?.replacingOccurrences(of: "www.", with: "") ?? url.absoluteString)
                            .font(Typography.subheadline)
                            .lineLimit(1)
                    }
                    .foregroundStyle(ResurfaceTheme.Colors.accent)
                }
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(spacing: Spacing.sm) {
            // Metadata row
            HStack(spacing: Spacing.md) {
                metadataItem(
                    icon: "calendar",
                    label: "Saved",
                    value: item.createdAt.formatted(date: .abbreviated, time: .omitted)
                )

                Divider()
                    .frame(height: 24)
                    .background(ResurfaceTheme.Colors.border)

                metadataItem(
                    icon: item.processingStatus.iconName,
                    label: "Status",
                    value: item.processingStatus.displayName
                )

                if let category = item.category {
                    Divider()
                        .frame(height: 24)
                        .background(ResurfaceTheme.Colors.border)

                    metadataItem(
                        icon: category.icon,
                        label: "Category",
                        value: category.name,
                        color: Color(hex: category.color)
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(ResurfaceTheme.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius.large)
                .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
        )
    }

    private func metadataItem(icon: String, label: String, value: String, color: Color? = nil) -> some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color ?? ResurfaceTheme.Colors.textSecondary)

            Text(value)
                .font(Typography.captionMedium)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

            Text(label)
                .font(Typography.micro)
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(
                title: "Key Insights",
                icon: "lightbulb.fill",
                iconColor: .yellow
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(item.keyInsights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                            .foregroundStyle(ResurfaceTheme.Colors.accent)
                            .padding(.top, 2)

                        Text(insight)
                            .font(Typography.subheadline)
                            .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(Spacing.md)
            .background(ResurfaceTheme.Colors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius.large)
                    .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Tags")

            FlowLayout(spacing: Spacing.xs) {
                ForEach(item.tags) { tag in
                    Text(tag.name)
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(ResurfaceTheme.Colors.surfaceFallback)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
                        )
                }
            }
        }
    }

    // MARK: - Content Section

    private func contentSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Content")

            Text(text)
                .font(Typography.body)
                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ResurfaceTheme.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadius.large)
                        .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleItem = {
        let item = BookmarkItem(
            contentType: .article,
            title: "How to Build Beautiful iOS Apps with SwiftUI and Modern Design Patterns",
            sourceURL: URL(string: "https://developer.apple.com/tutorials")
        )
        item.isFavorite = true
        item.keyInsights = [
            "SwiftUI provides declarative syntax for building user interfaces",
            "Combine can be used for reactive programming patterns",
            "Use @Observable for modern state management"
        ]
        return item
    }()

    NavigationStack {
        BookmarkDetailView(item: sampleItem)
    }
    .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
    .preferredColorScheme(.dark)
}
