import SwiftUI

/// Rich bookmark card with thumbnail, metadata, and status indicators
struct BookmarkCard: View {
    let item: BookmarkItem
    var style: CardStyle = .grid

    enum CardStyle {
        case grid       // 2-column grid layout
        case horizontal // Horizontal scroll layout
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail with overlays
            thumbnailSection

            // Content section
            contentSection
        }
        .background(ResurfaceTheme.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius.large)
                .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
        )
    }

    // MARK: - Thumbnail Section

    private var thumbnailSection: some View {
        ZStack(alignment: .topLeading) {
            // Thumbnail
            ThumbnailView(
                contentType: item.contentType,
                categoryColor: nil,
                size: .large,
                thumbnailPath: item.thumbnailPath
            )

            // Top overlay: Content type badge
            ContentTypeBadge(contentType: item.contentType)
                .padding(Spacing.xs)

            // Bottom overlay: Gradient + favorite
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.yellow)
                            .padding(6)
                            .background(ResurfaceTheme.Colors.backgroundFallback.opacity(0.8))
                            .clipShape(Circle())
                            .padding(Spacing.xs)
                    }
                }
            }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            // Title
            Text(item.displayTitle)
                .font(Typography.subheadlineMedium)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Metadata row
            HStack(spacing: Spacing.xs) {
                // Source domain
                if let host = item.sourceURL?.host?.replacingOccurrences(of: "www.", with: "") {
                    Text(host)
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                        .lineLimit(1)
                }

                // Separator dot
                if item.sourceURL?.host != nil {
                    Circle()
                        .fill(ResurfaceTheme.Colors.textTertiary)
                        .frame(width: 3, height: 3)
                }

                // Relative time
                Text(item.createdAt, style: .relative)
                    .font(Typography.caption)
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)

                Spacer()

                // Processing indicators
                if item.isPending {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundStyle(ResurfaceTheme.Colors.warning)
                } else if item.aiProcessingStatus == .processing {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(ResurfaceTheme.Colors.accent)
                        .symbolEffect(.pulse.byLayer)
                } else if item.isAIProcessed {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(ResurfaceTheme.Colors.success)
                }
            }

            // Category pill (if assigned)
            if let category = item.category {
                CategoryPill(category: category, style: .compact)
                    .padding(.top, Spacing.xxs)
            }

            // Resurface indicator
            if item.isResurfacePending, let description = item.resurfaceDescription {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 10))
                    Text(description)
                        .font(Typography.micro)
                }
                .foregroundStyle(ResurfaceTheme.Colors.accent)
                .padding(.top, Spacing.xxs)
            }
        }
        .padding(Spacing.sm)
    }
}

// MARK: - Compact Card Variant

struct BookmarkCardCompact: View {
    let item: BookmarkItem

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Thumbnail
            ThumbnailView(
                contentType: item.contentType,
                categoryColor: nil,
                size: .small,
                thumbnailPath: item.thumbnailPath
            )

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.displayTitle)
                    .font(Typography.subheadlineMedium)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                    .lineLimit(2)

                HStack(spacing: Spacing.xxs) {
                    if let host = item.sourceURL?.host?.replacingOccurrences(of: "www.", with: "") {
                        Text(host)
                            .font(Typography.caption)
                            .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Indicators
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
                } else if item.isAIProcessed {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundStyle(ResurfaceTheme.Colors.success)
                }
            }
        }
        .padding(Spacing.sm)
        .background(ResurfaceTheme.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium)
                .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    let sampleItem = {
        let item = BookmarkItem(
            contentType: .article,
            title: "How to Build Beautiful iOS Apps with SwiftUI",
            sourceURL: URL(string: "https://www.apple.com/developer")
        )
        item.isFavorite = true
        return item
    }()

    let sampleItem2 = {
        let item = BookmarkItem(
            contentType: .youtube,
            title: "WWDC 2024 Keynote - All New Features",
            sourceURL: URL(string: "https://youtube.com/watch?v=abc123")
        )
        return item
    }()

    let sampleItem3 = {
        let item = BookmarkItem(
            contentType: .image,
            title: "Screenshot 2024-03-15"
        )
        return item
    }()

    ScrollView {
        VStack(spacing: Spacing.lg) {
            Text("Grid Cards")
                .textStyle(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                BookmarkCard(item: sampleItem)
                BookmarkCard(item: sampleItem2)
                BookmarkCard(item: sampleItem3)
                BookmarkCard(item: sampleItem)
            }

            Text("Compact Cards")
                .textStyle(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.md)

            VStack(spacing: Spacing.xs) {
                BookmarkCardCompact(item: sampleItem)
                BookmarkCardCompact(item: sampleItem2)
                BookmarkCardCompact(item: sampleItem3)
            }
        }
        .padding()
    }
    .background(ResurfaceTheme.Colors.backgroundFallback)
}
