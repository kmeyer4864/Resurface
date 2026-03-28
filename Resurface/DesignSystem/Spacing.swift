import SwiftUI

// MARK: - Spacing Scale

struct Spacing {

    // MARK: - Base Spacing Scale

    /// 4pt - Tight spacing
    static let xxs: CGFloat = 4

    /// 8pt - Small spacing
    static let xs: CGFloat = 8

    /// 12pt - Compact spacing
    static let sm: CGFloat = 12

    /// 16pt - Default spacing
    static let md: CGFloat = 16

    /// 20pt - Medium-large spacing
    static let lg: CGFloat = 20

    /// 24pt - Large spacing
    static let xl: CGFloat = 24

    /// 32pt - Extra large spacing
    static let xxl: CGFloat = 32

    /// 48pt - Section spacing
    static let xxxl: CGFloat = 48

    // MARK: - Corner Radius

    struct cornerRadius {
        /// 6pt - Small elements (tags, badges)
        static let small: CGFloat = 6

        /// 10pt - Medium elements (buttons, inputs)
        static let medium: CGFloat = 10

        /// 14pt - Cards and containers
        static let large: CGFloat = 14

        /// 20pt - Large cards, modals
        static let xl: CGFloat = 20

        /// Full rounded (capsule)
        static let full: CGFloat = 9999
    }

    // MARK: - Layout

    struct layout {
        /// Standard horizontal padding
        static let horizontalPadding: CGFloat = 16

        /// Standard vertical padding
        static let verticalPadding: CGFloat = 16

        /// Card internal padding
        static let cardPadding: CGFloat = 14

        /// Grid gap
        static let gridGap: CGFloat = 12

        /// Section gap
        static let sectionGap: CGFloat = 28

        /// Tab bar height
        static let tabBarHeight: CGFloat = 49

        /// Navigation bar height
        static let navBarHeight: CGFloat = 44

        /// Card thumbnail height
        static let thumbnailHeight: CGFloat = 120

        /// Compact card thumbnail height
        static let thumbnailHeightCompact: CGFloat = 80

        /// Row icon size
        static let iconSize: CGFloat = 44

        /// Small icon size
        static let iconSizeSmall: CGFloat = 32
    }

    // MARK: - Animation Durations

    struct animation {
        static let fast: Double = 0.15
        static let normal: Double = 0.25
        static let slow: Double = 0.35

        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
        static let springFast = Animation.spring(response: 0.25, dampingFraction: 0.8)
        static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - Convenience Padding Modifiers

extension View {
    /// Standard horizontal padding
    func horizontalPadding() -> some View {
        self.padding(.horizontal, Spacing.layout.horizontalPadding)
    }

    /// Standard card padding
    func cardPadding() -> some View {
        self.padding(Spacing.layout.cardPadding)
    }

    /// Section spacing from previous element
    func sectionSpacing() -> some View {
        self.padding(.top, Spacing.layout.sectionGap)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Spacing Scale")
                .textStyle(.title2)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                spacingSwatch("xxs (4)", Spacing.xxs)
                spacingSwatch("xs (8)", Spacing.xs)
                spacingSwatch("sm (12)", Spacing.sm)
                spacingSwatch("md (16)", Spacing.md)
                spacingSwatch("lg (20)", Spacing.lg)
                spacingSwatch("xl (24)", Spacing.xl)
                spacingSwatch("xxl (32)", Spacing.xxl)
            }

            Text("Corner Radius")
                .textStyle(.title2)
                .padding(.top, Spacing.lg)

            HStack(spacing: Spacing.md) {
                radiusSwatch("S", Spacing.cornerRadius.small)
                radiusSwatch("M", Spacing.cornerRadius.medium)
                radiusSwatch("L", Spacing.cornerRadius.large)
                radiusSwatch("XL", Spacing.cornerRadius.xl)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    .background(ResurfaceTheme.Colors.backgroundFallback)
}

private func spacingSwatch(_ label: String, _ value: CGFloat) -> some View {
    HStack(spacing: Spacing.sm) {
        RoundedRectangle(cornerRadius: 4)
            .fill(ResurfaceTheme.Colors.accent)
            .frame(width: value, height: 24)

        Text(label)
            .textStyle(.caption)
    }
}

private func radiusSwatch(_ label: String, _ radius: CGFloat) -> some View {
    VStack(spacing: Spacing.xxs) {
        RoundedRectangle(cornerRadius: radius)
            .fill(ResurfaceTheme.Colors.surfaceElevatedFallback)
            .frame(width: 50, height: 50)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(ResurfaceTheme.Colors.accent, lineWidth: 2)
            )
        Text(label)
            .textStyle(.micro)
    }
}
