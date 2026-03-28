import SwiftUI

/// Section header with title and optional "See All" action
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var iconColor: Color? = nil
    var showSeeAll: Bool = false
    var seeAllAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.xs) {
            // Icon (optional)
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor ?? ResurfaceTheme.Colors.accent)
            }

            // Title + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
            }

            Spacer()

            // See All button
            if showSeeAll {
                Button(action: { seeAllAction?() }) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(Typography.captionMedium)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(ResurfaceTheme.Colors.accent)
                }
            }
        }
    }
}

// MARK: - Greeting Header

struct GreetingHeader: View {
    var itemCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(greeting)
                .font(Typography.title2)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

            if itemCount > 0 {
                Text("\(itemCount) items in your collection")
                    .font(Typography.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
            } else {
                Text("Start saving content to your collection")
                    .font(Typography.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 0..<5:
            return "Good night"
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<21:
            return "Good evening"
        default:
            return "Good night"
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(ResurfaceTheme.Colors.accentSubtle)
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(ResurfaceTheme.Colors.accent)
            }

            // Text
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.title3)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                Text(description)
                    .font(Typography.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Typography.subheadlineMedium)
                        .foregroundStyle(ResurfaceTheme.Colors.accent)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(ResurfaceTheme.Colors.accentSubtle)
                        .clipShape(Capsule())
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            // Greeting
            GreetingHeader(itemCount: 42)
                .padding(.horizontal)

            Divider()
                .background(ResurfaceTheme.Colors.border)

            // Section headers
            VStack(spacing: Spacing.lg) {
                SectionHeader(title: "Recent")
                    .padding(.horizontal)

                SectionHeader(
                    title: "Tech",
                    icon: "cpu.fill",
                    iconColor: Color(hex: "#5856D6"),
                    showSeeAll: true
                ) {
                    print("See all tapped")
                }
                .padding(.horizontal)

                SectionHeader(
                    title: "Favorites",
                    subtitle: "Your starred items",
                    icon: "star.fill",
                    iconColor: .yellow,
                    showSeeAll: true
                ) {
                    print("See all tapped")
                }
                .padding(.horizontal)
            }

            Divider()
                .background(ResurfaceTheme.Colors.border)

            // Empty state
            EmptyStateView(
                icon: "tray",
                title: "No Bookmarks Yet",
                description: "Share content from any app to save it to your collection.",
                actionTitle: "Learn How"
            ) {
                print("Learn how tapped")
            }

            // Empty state without action
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No Results",
                description: "Try a different search term or filter."
            )
        }
        .padding(.vertical)
    }
    .background(ResurfaceTheme.Colors.backgroundFallback)
}
