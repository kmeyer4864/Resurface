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
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }

    private var firstInsight: String? {
        item.keyInsights.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero thumbnail with gradient overlay
            thumbnailHero

            // Content area
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Top row: content type + source + time
                metadataRow

                // Title
                Text(item.displayTitle)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Key insight snippet
                if let insight = firstInsight {
                    Text(insight)
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Bottom row: reason + actions
                bottomRow
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .resurfaceCard()
    }

    // MARK: - Thumbnail Hero

    private var thumbnailHero: some View {
        ZStack(alignment: .bottomLeading) {
            ThumbnailView(
                contentType: item.contentType,
                categoryColor: nil,
                size: .large,
                thumbnailPath: item.thumbnailPath
            )
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipped()

            // Gradient overlay for readability
            LinearGradient(
                colors: [
                    .clear,
                    .clear,
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)

            // Category pill overlaid on thumbnail
            if let category = item.category {
                HStack(spacing: 3) {
                    Text(category.emoji)
                        .font(.system(size: 11))
                    Text(category.name)
                        .font(Typography.micro)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(Spacing.sm)
            }
        }
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: Spacing.xs) {
            // Content type badge
            ContentTypeBadge(contentType: item.contentType)

            Spacer()

            // Source + time
            HStack(spacing: 4) {
                Image(systemName: sourceInfo.icon)
                    .font(.system(size: 9))
                Text(sourceInfo.name)
                    .font(Typography.micro)
                Text("·")
                    .font(Typography.micro)
                Text(timeContext)
                    .font(Typography.micro)
            }
            .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
        }
    }

    // MARK: - Bottom Row

    private var bottomRow: some View {
        HStack(spacing: Spacing.sm) {
            // Reason label
            HStack(spacing: 3) {
                Image(systemName: resurfaceItem.reason.icon)
                    .font(.system(size: 9))
                Text(resurfaceItem.reason.label)
                    .font(Typography.micro)
            }
            .foregroundStyle(ResurfaceTheme.Colors.accent)

            Spacer()

            // Action buttons — compact icon style
            Button {
                onSnooze()
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
                    .clipShape(Circle())
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
                    .clipShape(Circle())
            }
        }
    }
}
