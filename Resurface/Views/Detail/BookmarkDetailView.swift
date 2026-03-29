import SwiftUI
import SwiftData

struct BookmarkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: BookmarkItem
    @State private var isRetryingAI = false
    @State private var showImagePreview = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Hero thumbnail
                heroSection

                // Open Original button - prominent access to the original content
                openOriginalButton
                    .padding(.horizontal, Spacing.layout.horizontalPadding)

                // Content
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    headerSection
                    metadataSection

                    // Dynamic extracted fields (category-specific)
                    if !item.extractedFields.isEmpty {
                        extractedFieldsSection
                    }

                    // AI status for pending/failed items
                    if item.needsAIProcessing {
                        aiStatusSection
                    }

                    if !item.keyInsights.isEmpty {
                        insightsSection
                    }

                    if !item.tags.isEmpty {
                        tagsSection
                    }

                    // Resurface section
                    resurfaceSection

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
        .fullScreenCover(isPresented: $showImagePreview) {
            if let thumbnailPath = item.thumbnailPath {
                ImagePreviewView(imagePath: thumbnailPath, title: item.displayTitle)
            }
        }
    }

    // MARK: - Open Original Button

    @ViewBuilder
    private var openOriginalButton: some View {
        // Different actions based on content type
        if let url = item.sourceURL {
            // URL-based content - open in browser
            Link(destination: url) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.system(size: 18))
                    Text("Open Original")
                        .font(Typography.bodyMedium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .foregroundStyle(ResurfaceTheme.Colors.accent)
                .padding(Spacing.md)
                .background(ResurfaceTheme.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadius.large)
                        .stroke(ResurfaceTheme.Colors.accent.opacity(0.3), lineWidth: 1)
                )
            }
        } else if item.contentType == .image || item.contentType == .screenshot {
            // Image content - show full screen preview
            Button {
                showImagePreview = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 18))
                    Text("View Full Image")
                        .font(Typography.bodyMedium)
                    Spacer()
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .foregroundStyle(ResurfaceTheme.Colors.accent)
                .padding(Spacing.md)
                .background(ResurfaceTheme.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadius.large)
                        .stroke(ResurfaceTheme.Colors.accent.opacity(0.3), lineWidth: 1)
                )
            }
        } else if item.contentType == .pdf, let mediaPath = item.mediaPath {
            // PDF content - share/open action
            ShareLink(item: URL(fileURLWithPath: mediaPath)) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 18))
                    Text("Open PDF")
                        .font(Typography.bodyMedium)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .foregroundStyle(ResurfaceTheme.Colors.accent)
                .padding(Spacing.md)
                .background(ResurfaceTheme.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadius.large)
                        .stroke(ResurfaceTheme.Colors.accent.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Large thumbnail
            ThumbnailView(
                contentType: item.contentType,
                categoryColor: nil,
                size: .large,
                thumbnailPath: item.thumbnailPath
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

                    VStack(spacing: Spacing.xxs) {
                        Text(category.emoji)
                            .font(.system(size: 20))

                        Text(category.name)
                            .font(Typography.captionMedium)
                            .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                        Text("Category")
                            .font(Typography.micro)
                            .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }

                if item.isAIProcessed, let confidence = item.aiConfidence {
                    Divider()
                        .frame(height: 24)
                        .background(ResurfaceTheme.Colors.border)

                    metadataItem(
                        icon: "sparkles",
                        label: "AI",
                        value: "\(Int(confidence * 100))%",
                        color: confidenceColor(confidence)
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

    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        default:
            return .orange
        }
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

    // MARK: - Extracted Fields Section (Dynamic, Category-Specific)

    private var extractedFieldsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Use category name as section title, or default to "Details"
            SectionHeader(
                title: item.category.map { "\($0.emoji) \($0.name) Details" } ?? "Details",
                icon: "doc.text.magnifyingglass",
                iconColor: ResurfaceTheme.Colors.accent
            )

            VStack(spacing: 0) {
                ForEach(Array(item.extractedFields.keys.sorted().enumerated()), id: \.element) { index, key in
                    extractedFieldRow(key: key, value: item.extractedFields[key] ?? "")

                    if index < item.extractedFields.count - 1 {
                        Divider()
                            .background(ResurfaceTheme.Colors.border)
                    }
                }
            }
            .background(ResurfaceTheme.Colors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius.large)
                    .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
            )
        }
    }

    private func extractedFieldRow(key: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .font(Typography.caption)
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(Typography.subheadlineMedium)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Copy button for values
            Button {
                UIPasteboard.general.string = value
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
    }

    // MARK: - AI Status Section

    private var aiStatusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(
                title: "AI Analysis",
                icon: item.aiProcessingStatus.iconName,
                iconColor: item.aiProcessingStatus == .failed ? .red : .orange
            )

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(item.aiProcessingStatus.displayName)
                        .font(Typography.subheadlineMedium)
                        .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                    Text(aiStatusDescription)
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }

                Spacer()

                Button {
                    retryAIProcessing()
                } label: {
                    if isRetryingAI {
                        ProgressView()
                            .tint(ResurfaceTheme.Colors.accent)
                    } else {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .font(Typography.captionMedium)
                            .foregroundStyle(ResurfaceTheme.Colors.accent)
                    }
                }
                .disabled(isRetryingAI)
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

    private var aiStatusDescription: String {
        switch item.aiProcessingStatus {
        case .pending:
            return "AI analysis will run when online"
        case .processing:
            return "Analyzing content..."
        case .failed:
            return "Analysis failed. Tap to retry."
        case .skipped:
            return "Not enough content to analyze"
        case .completed:
            return "Analysis complete"
        }
    }

    private func retryAIProcessing() {
        isRetryingAI = true
        Task {
            await BackgroundProcessor.shared.retryAIProcessing(for: item, in: modelContext)
            isRetryingAI = false
        }
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

    // MARK: - Resurface Section

    private var resurfaceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(
                title: "Resurface Reminder",
                icon: "bell.fill",
                iconColor: ResurfaceTheme.Colors.accent
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let resurfaceAt = item.resurfaceAt {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            if resurfaceAt > Date() {
                                Text("Scheduled for")
                                    .font(Typography.caption)
                                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                                Text(resurfaceAt, style: .date)
                                    .font(Typography.subheadlineMedium)
                                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                            } else {
                                Text("Ready to resurface!")
                                    .font(Typography.subheadlineMedium)
                                    .foregroundStyle(ResurfaceTheme.Colors.accent)
                            }
                        }

                        Spacer()

                        Button {
                            clearResurface()
                        } label: {
                            Text("Clear")
                                .font(Typography.caption)
                                .foregroundStyle(ResurfaceTheme.Colors.error)
                        }
                    }
                } else {
                    // Picker to set resurface time
                    Text("Set a reminder to revisit this content")
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(ResurfaceOption.allCases.filter { $0 != .never }) { option in
                                Button {
                                    setResurface(option)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: option.iconName)
                                            .font(.system(size: 12))
                                        Text(option.shortName)
                                            .font(Typography.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
                                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
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

    private func setResurface(_ option: ResurfaceOption) {
        guard let targetDate = option.targetDate() else { return }

        item.resurfaceAt = targetDate

        Task {
            let notificationId = await ResurfaceNotificationService.shared.scheduleNotification(
                for: item.id,
                title: item.displayTitle,
                at: targetDate
            )
            await MainActor.run {
                item.resurfaceNotificationId = notificationId
                try? modelContext.save()
            }
        }
    }

    private func clearResurface() {
        if let notificationId = item.resurfaceNotificationId {
            Task {
                await ResurfaceNotificationService.shared.cancelNotification(identifier: notificationId)
            }
        }

        item.resurfaceAt = nil
        item.resurfaceNotificationId = nil
        try? modelContext.save()
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

// MARK: - Image Preview View

struct ImagePreviewView: View {
    let imagePath: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if let uiImage = UIImage(contentsOfFile: imagePath) {
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .frame(
                                width: geometry.size.width * scale,
                                height: geometry.size.height * scale
                            )
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 1), 4)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            scale = scale > 1 ? 1 : 2
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Image Not Found",
                        systemImage: "photo.badge.exclamationmark",
                        description: Text("The original image could not be loaded.")
                    )
                }
            }
            .background(Color.black)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if let uiImage = UIImage(contentsOfFile: imagePath) {
                        ShareLink(item: Image(uiImage: uiImage), preview: SharePreview(title, image: Image(uiImage: uiImage)))
                    }
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

#Preview("Article") {
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

#Preview("HSA Receipt with Extracted Fields") {
    let sampleItem = {
        let item = BookmarkItem(
            contentType: .pdf,
            title: "Headway Therapy Invoice"
        )
        item.aiGeneratedTitle = "Headway Therapy - $100"
        item.keyInsights = [
            "Therapy session on February 6, 2026",
            "Payment completed via insurance"
        ]
        item.extractedFields = [
            "Provider": "Headway - Khurshed Davronov",
            "Amount": "$100.00",
            "Date of Service": "February 6, 2026",
            "Payment Status": "Paid",
            "Service Type": "Therapy Session"
        ]
        return item
    }()

    NavigationStack {
        BookmarkDetailView(item: sampleItem)
    }
    .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
    .preferredColorScheme(.dark)
}
