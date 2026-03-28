import SwiftUI

/// Smart thumbnail view that displays real thumbnails or fallback content type icon with gradient
struct ThumbnailView: View {
    let contentType: ContentType
    let categoryColor: String?
    let size: ThumbnailSize
    let thumbnailPath: String?

    @State private var thumbnailImage: UIImage?
    @State private var isLoading: Bool = false

    enum ThumbnailSize {
        case small      // 44x44 - for list rows
        case medium     // 80x80 - for compact cards
        case large      // 120 height - for full cards

        var height: CGFloat {
            switch self {
            case .small: return 44
            case .medium: return 80
            case .large: return 120
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 18
            case .medium: return 28
            case .large: return 36
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return Spacing.cornerRadius.small
            case .medium: return Spacing.cornerRadius.medium
            case .large: return Spacing.cornerRadius.large
            }
        }
    }

    init(
        contentType: ContentType,
        categoryColor: String? = nil,
        size: ThumbnailSize = .large,
        thumbnailPath: String? = nil
    ) {
        self.contentType = contentType
        self.categoryColor = categoryColor
        self.size = size
        self.thumbnailPath = thumbnailPath
    }

    var body: some View {
        ZStack {
            if let image = thumbnailImage {
                // Real thumbnail image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                // Loading state
                gradientBackground
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
                    .tint(ResurfaceTheme.Colors.textTertiary)
            } else {
                // Fallback gradient with icon
                gradientBackground
                Image(systemName: contentType.iconName)
                    .font(.system(size: size.iconSize, weight: .medium))
                    .foregroundStyle(iconColor)
            }
        }
        .frame(height: size.height)
        .frame(maxWidth: size == .small ? size.height : .infinity)
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        .task(id: thumbnailPath) {
            await loadThumbnail()
        }
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail() async {
        guard let path = thumbnailPath, !path.isEmpty else {
            thumbnailImage = nil
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Load on background thread
        let image = await Task.detached(priority: .userInitiated) {
            ThumbnailService.shared.loadThumbnail(relativePath: path)
        }.value

        // Update on main thread
        await MainActor.run {
            withAnimation(.easeIn(duration: 0.2)) {
                self.thumbnailImage = image
            }
        }
    }

    // MARK: - Fallback Styles

    private var gradientBackground: some View {
        Group {
            if let hex = categoryColor, let color = Color(hex: hex) {
                LinearGradient(
                    colors: [
                        color.opacity(0.3),
                        color.opacity(0.1),
                        ResurfaceTheme.Colors.surfaceFallback
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                contentTypeGradient
            }
        }
    }

    private var contentTypeGradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var gradientColors: [Color] {
        switch contentType {
        case .youtube, .video:
            return [
                Color(red: 0.9, green: 0.2, blue: 0.2).opacity(0.3),
                ResurfaceTheme.Colors.surfaceFallback
            ]
        case .article, .pdf:
            return [
                ResurfaceTheme.Colors.accent.opacity(0.25),
                ResurfaceTheme.Colors.surfaceFallback
            ]
        case .image, .screenshot:
            return [
                Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.3),
                ResurfaceTheme.Colors.surfaceFallback
            ]
        case .socialPost:
            return [
                Color(red: 0.9, green: 0.4, blue: 0.6).opacity(0.3),
                ResurfaceTheme.Colors.surfaceFallback
            ]
        default:
            return [
                ResurfaceTheme.Colors.surfaceElevatedFallback,
                ResurfaceTheme.Colors.surfaceFallback
            ]
        }
    }

    private var iconColor: Color {
        if categoryColor != nil {
            return ResurfaceTheme.Colors.textSecondary
        }

        switch contentType {
        case .youtube, .video:
            return Color(red: 0.95, green: 0.3, blue: 0.3)
        case .article, .pdf:
            return ResurfaceTheme.Colors.accent.opacity(0.8)
        case .image, .screenshot:
            return Color(red: 0.3, green: 0.7, blue: 0.95)
        case .socialPost:
            return Color(red: 0.95, green: 0.5, blue: 0.7)
        default:
            return ResurfaceTheme.Colors.textTertiary
        }
    }
}

// MARK: - Content Type Badge

struct ContentTypeBadge: View {
    let contentType: ContentType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: contentType.iconName)
                .font(.system(size: 10, weight: .semibold))

            Text(contentType.displayName.uppercased())
                .font(Typography.micro)
        }
        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ResurfaceTheme.Colors.backgroundFallback.opacity(0.8))
        .clipShape(Capsule())
    }
}

// MARK: - Processing Status Indicator

struct ProcessingStatusIndicator: View {
    let status: ProcessingStatus

    var body: some View {
        Group {
            switch status {
            case .pending, .processing:
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Processing...")
                        .font(Typography.micro)
                }
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ResurfaceTheme.Colors.backgroundFallback.opacity(0.8))
                .clipShape(Capsule())

            case .failed:
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text("Failed")
                        .font(Typography.micro)
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ResurfaceTheme.Colors.backgroundFallback.opacity(0.8))
                .clipShape(Capsule())

            case .completed:
                EmptyView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            Text("Large Thumbnails")
                .textStyle(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                ForEach(ContentType.allCases, id: \.self) { type in
                    VStack(spacing: Spacing.xs) {
                        ThumbnailView(contentType: type, size: .large)
                        Text(type.displayName)
                            .textStyle(.caption)
                    }
                }
            }

            Text("Medium Thumbnails")
                .textStyle(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.md)

            HStack(spacing: Spacing.sm) {
                ForEach([ContentType.article, .youtube, .image], id: \.self) { type in
                    ThumbnailView(contentType: type, size: .medium)
                }
            }

            Text("Small Thumbnails")
                .textStyle(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.md)

            HStack(spacing: Spacing.sm) {
                ForEach([ContentType.url, .pdf, .socialPost], id: \.self) { type in
                    ThumbnailView(contentType: type, size: .small)
                }
            }

            Text("With Category Color")
                .textStyle(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.md)

            HStack(spacing: Spacing.sm) {
                ThumbnailView(contentType: .article, categoryColor: "#FF2D55", size: .medium)
                ThumbnailView(contentType: .url, categoryColor: "#34C759", size: .medium)
                ThumbnailView(contentType: .video, categoryColor: "#5856D6", size: .medium)
            }

            Text("Content Type Badges")
                .textStyle(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.md)

            HStack(spacing: Spacing.sm) {
                ContentTypeBadge(contentType: .article)
                ContentTypeBadge(contentType: .youtube)
                ContentTypeBadge(contentType: .image)
            }

            Text("Processing Status")
                .textStyle(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.md)

            HStack(spacing: Spacing.sm) {
                ProcessingStatusIndicator(status: .pending)
                ProcessingStatusIndicator(status: .failed)
            }
        }
        .padding()
    }
    .background(ResurfaceTheme.Colors.backgroundFallback)
}
