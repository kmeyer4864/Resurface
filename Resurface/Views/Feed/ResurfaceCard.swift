import SwiftUI

struct ResurfaceCard: View {
    let resurfaceItem: ResurfaceEngine.ResurfaceItem
    let onDismiss: () -> Void
    let onSnooze: () -> Void

    private var item: BookmarkItem { resurfaceItem.item }

    private var sourceInfo: SourceExtractor.SourceInfo {
        SourceExtractor.bestSource(url: item.sourceURL, sourceApp: item.sourceApp)
    }

    private var timeContext: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Saved \(formatter.localizedString(for: item.createdAt, relativeTo: Date()))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ThumbnailView(
                contentType: item.contentType,
                categoryColor: nil,
                size: .large,
                thumbnailPath: item.thumbnailPath
            )
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipped()

            // Content
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Reason label
                HStack(spacing: 4) {
                    Image(systemName: resurfaceItem.reason.icon)
                        .font(.system(size: 10))
                    Text(resurfaceItem.reason.label)
                        .font(Typography.micro)
                }
                .foregroundStyle(ResurfaceTheme.Colors.accent)

                // Title
                Text(item.displayTitle)
                    .font(Typography.subheadlineMedium)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Source + time context
                HStack(spacing: Spacing.xs) {
                    HStack(spacing: 2) {
                        Image(systemName: sourceInfo.icon)
                            .font(.system(size: 9))
                        Text(sourceInfo.name)
                            .font(Typography.micro)
                    }
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)

                    Circle()
                        .fill(ResurfaceTheme.Colors.textTertiary)
                        .frame(width: 2, height: 2)

                    Text(timeContext)
                        .font(Typography.micro)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }

                // Category pill
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

                // Actions
                HStack(spacing: Spacing.sm) {
                    Spacer()

                    Button {
                        onSnooze()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 12))
                            Text("Tomorrow")
                                .font(Typography.caption)
                        }
                        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
                        .clipShape(Capsule())
                    }

                    Button {
                        onDismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                            Text("Dismiss")
                                .font(Typography.caption)
                        }
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(Spacing.md)
        }
        .resurfaceCard()
    }
}
