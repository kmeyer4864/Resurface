import SwiftUI

// MARK: - Typography Scale

struct Typography {

    // MARK: - Font Sizes

    struct Size {
        static let micro: CGFloat = 10
        static let caption: CGFloat = 12
        static let footnote: CGFloat = 13
        static let subheadline: CGFloat = 15
        static let body: CGFloat = 17
        static let headline: CGFloat = 17  // Same size as body, different weight
        static let title3: CGFloat = 20
        static let title2: CGFloat = 22
        static let title1: CGFloat = 28
        static let largeTitle: CGFloat = 34
    }

    // MARK: - Text Styles

    /// Large title for main headers
    static let largeTitle = Font.system(size: Size.largeTitle, weight: .bold, design: .default)

    /// Title for section headers
    static let title1 = Font.system(size: Size.title1, weight: .bold, design: .default)

    /// Secondary title
    static let title2 = Font.system(size: Size.title2, weight: .semibold, design: .default)

    /// Tertiary title
    static let title3 = Font.system(size: Size.title3, weight: .semibold, design: .default)

    /// Headlines (bold body text)
    static let headline = Font.system(size: Size.headline, weight: .semibold, design: .default)

    /// Body text
    static let body = Font.system(size: Size.body, weight: .regular, design: .default)

    /// Body text medium weight
    static let bodyMedium = Font.system(size: Size.body, weight: .medium, design: .default)

    /// Subheadline for secondary content
    static let subheadline = Font.system(size: Size.subheadline, weight: .regular, design: .default)

    /// Subheadline medium weight
    static let subheadlineMedium = Font.system(size: Size.subheadline, weight: .medium, design: .default)

    /// Footnotes and small text
    static let footnote = Font.system(size: Size.footnote, weight: .regular, design: .default)

    /// Captions for metadata
    static let caption = Font.system(size: Size.caption, weight: .regular, design: .default)

    /// Caption medium weight
    static let captionMedium = Font.system(size: Size.caption, weight: .medium, design: .default)

    /// Micro text for badges/tags
    static let micro = Font.system(size: Size.micro, weight: .medium, design: .default)

    // MARK: - Monospace (for counts, numbers)

    static let monoCaption = Font.system(size: Size.caption, weight: .medium, design: .monospaced)
    static let monoBody = Font.system(size: Size.body, weight: .medium, design: .monospaced)
}

// MARK: - Text Style Modifiers

extension View {
    func textStyle(_ style: TextStyle) -> some View {
        self.modifier(TextStyleModifier(style: style))
    }
}

enum TextStyle {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case bodySecondary
    case subheadline
    case subheadlineSecondary
    case caption
    case captionSecondary
    case micro
}

struct TextStyleModifier: ViewModifier {
    let style: TextStyle

    func body(content: Content) -> some View {
        switch style {
        case .largeTitle:
            content
                .font(Typography.largeTitle)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
        case .title1:
            content
                .font(Typography.title1)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
        case .title2:
            content
                .font(Typography.title2)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
        case .title3:
            content
                .font(Typography.title3)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
        case .headline:
            content
                .font(Typography.headline)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
        case .body:
            content
                .font(Typography.body)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
        case .bodySecondary:
            content
                .font(Typography.body)
                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
        case .subheadline:
            content
                .font(Typography.subheadline)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
        case .subheadlineSecondary:
            content
                .font(Typography.subheadline)
                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
        case .caption:
            content
                .font(Typography.caption)
                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
        case .captionSecondary:
            content
                .font(Typography.caption)
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
        case .micro:
            content
                .font(Typography.micro)
                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Text("Large Title")
                .textStyle(.largeTitle)

            Text("Title 1")
                .textStyle(.title1)

            Text("Title 2")
                .textStyle(.title2)

            Text("Title 3")
                .textStyle(.title3)

            Text("Headline")
                .textStyle(.headline)

            Text("Body text for reading")
                .textStyle(.body)

            Text("Body secondary")
                .textStyle(.bodySecondary)

            Text("Subheadline")
                .textStyle(.subheadline)

            Text("Subheadline secondary")
                .textStyle(.subheadlineSecondary)

            Text("Caption text")
                .textStyle(.caption)

            Text("Caption secondary")
                .textStyle(.captionSecondary)

            Text("MICRO TEXT")
                .textStyle(.micro)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    .background(ResurfaceTheme.Colors.backgroundFallback)
}
