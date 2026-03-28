import SwiftUI

/// Compact bookmark row for list views (deprecated in favor of BookmarkCardCompact)
/// Kept for backwards compatibility
struct BookmarkRowView: View {
    let item: BookmarkItem

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Thumbnail
            ThumbnailView(
                contentType: item.contentType,
                categoryColor: item.category?.color,
                size: .small
            )

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.displayTitle)
                    .font(Typography.subheadlineMedium)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                    .lineLimit(2)

                HStack(spacing: Spacing.xs) {
                    if let host = item.sourceURL?.host?.replacingOccurrences(of: "www.", with: "") {
                        Text(host)
                            .font(Typography.caption)
                            .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                            .lineLimit(1)
                    }

                    Text(item.createdAt, style: .relative)
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
            }

            Spacer()

            // Status indicators
            VStack(spacing: Spacing.xxs) {
                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.yellow)
                }

                if item.isPending {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(ResurfaceTheme.Colors.warning)
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    let sampleItem = BookmarkItem(
        contentType: .article,
        title: "How to Build iOS Apps with SwiftUI",
        sourceURL: URL(string: "https://developer.apple.com/tutorials")
    )

    let sampleItem2 = BookmarkItem(
        contentType: .youtube,
        title: "WWDC 2024 Keynote",
        sourceURL: URL(string: "https://youtube.com/watch?v=abc123")
    )

    VStack(spacing: Spacing.sm) {
        BookmarkRowView(item: sampleItem)
        BookmarkRowView(item: sampleItem2)
    }
    .padding()
    .background(ResurfaceTheme.Colors.backgroundFallback)
    .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
    .preferredColorScheme(.dark)
}
