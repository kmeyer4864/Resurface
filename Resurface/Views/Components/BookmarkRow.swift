import SwiftUI

/// Clean, scannable list row for bookmarks with swipe actions
struct BookmarkRow: View {
    let item: BookmarkItem

    // Swipe action callbacks
    var onFavorite: (() -> Void)?
    var onRemind: (() -> Void)?
    var onArchive: (() -> Void)?
    var onDelete: (() -> Void)?

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
                // Favorite indicator
                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                }

                // Resurface bell
                if item.isResurfacePending {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(ResurfaceTheme.Colors.accent)
                }

                // Processing indicator
                processingIndicator
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.layout.horizontalPadding)
        .background(ResurfaceTheme.Colors.backgroundFallback)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // Delete (furthest right, full swipe)
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            // Archive
            if let onArchive = onArchive {
                Button {
                    onArchive()
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(ResurfaceTheme.Colors.warning)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            // Favorite (full swipe)
            if let onFavorite = onFavorite {
                Button {
                    onFavorite()
                } label: {
                    Label(
                        item.isFavorite ? "Unfavorite" : "Favorite",
                        systemImage: item.isFavorite ? "star.slash" : "star.fill"
                    )
                }
                .tint(.yellow)
            }

            // Remind
            if let onRemind = onRemind {
                Button {
                    onRemind()
                } label: {
                    Label("Remind", systemImage: "bell")
                }
                .tint(ResurfaceTheme.Colors.accent)
            }
        }
    }

    // MARK: - Processing Indicator

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
        // Don't show anything for completed - keep it clean
    }
}

// MARK: - Preview

#Preview {
    let sampleItem1: BookmarkItem = {
        let item = BookmarkItem(
            contentType: .article,
            title: "How to Build Beautiful iOS Apps with SwiftUI",
            sourceURL: URL(string: "https://www.instagram.com/p/ABC123")
        )
        item.isFavorite = true
        return item
    }()

    let sampleItem2: BookmarkItem = {
        let item = BookmarkItem(
            contentType: .youtube,
            title: "WWDC 2024 Keynote - All New Features Announced",
            sourceURL: URL(string: "https://youtube.com/watch?v=abc123")
        )
        item.resurfaceAt = Date().addingTimeInterval(3600)
        item.resurfaceNotificationId = "test"
        return item
    }()

    let sampleItem3: BookmarkItem = {
        let item = BookmarkItem(
            contentType: .image,
            title: "Screenshot 2024-03-15"
        )
        item.sourceApp = "com.burbn.instagram"
        return item
    }()

    List {
        BookmarkRow(item: sampleItem1) {
            print("Favorite")
        } onRemind: {
            print("Remind")
        } onArchive: {
            print("Archive")
        } onDelete: {
            print("Delete")
        }

        BookmarkRow(item: sampleItem2) {
            print("Favorite")
        } onRemind: {
            print("Remind")
        } onArchive: {
            print("Archive")
        } onDelete: {
            print("Delete")
        }

        BookmarkRow(item: sampleItem3) {
            print("Favorite")
        } onRemind: {
            print("Remind")
        } onArchive: {
            print("Archive")
        } onDelete: {
            print("Delete")
        }
    }
    .listStyle(.plain)
    .background(ResurfaceTheme.Colors.backgroundFallback)
}
