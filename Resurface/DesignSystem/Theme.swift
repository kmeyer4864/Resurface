import SwiftUI

// MARK: - Resurface Theme
// Central theme configuration - change colors here to update entire app

struct ResurfaceTheme {

    // MARK: - Color Palette (Dark Moody)

    struct Colors {
        // Backgrounds
        static let background = Color("Background", bundle: nil)
        static let surface = Color("Surface", bundle: nil)
        static let surfaceElevated = Color("SurfaceElevated", bundle: nil)

        // With fallbacks for when asset catalog isn't set up
        static var backgroundFallback: Color {
            Color(red: 0.039, green: 0.039, blue: 0.043) // #0A0A0B
        }
        static var surfaceFallback: Color {
            Color(red: 0.078, green: 0.078, blue: 0.086) // #141416
        }
        static var surfaceElevatedFallback: Color {
            Color(red: 0.110, green: 0.110, blue: 0.122) // #1C1C1F
        }

        // Borders & Dividers
        static let border = Color(red: 0.165, green: 0.165, blue: 0.180) // #2A2A2E
        static let divider = Color(red: 0.165, green: 0.165, blue: 0.180).opacity(0.5)

        // Text
        static let textPrimary = Color(red: 0.961, green: 0.961, blue: 0.969) // #F5F5F7
        static let textSecondary = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
        static let textTertiary = Color(red: 0.388, green: 0.388, blue: 0.400) // #636366

        // Accent - Deep Purple (easy to swap)
        static let accent = Color(red: 0.545, green: 0.361, blue: 0.965) // #8B5CF6
        static let accentSubtle = accent.opacity(0.15)
        static let accentMuted = accent.opacity(0.6)

        // Alternative Accent - Teal (uncomment to use)
        // static let accent = Color(red: 0.078, green: 0.722, blue: 0.651) // #14B8A6

        // Semantic Colors
        static let success = Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759
        static let warning = Color(red: 1.0, green: 0.584, blue: 0.0)     // #FF9500
        static let error = Color(red: 1.0, green: 0.231, blue: 0.188)     // #FF3B30

        // Category Colors (for pills and accents)
        static func categoryColor(hex: String) -> Color {
            Color(hex: hex) ?? accent
        }

        // Gradients
        static let accentGradient = LinearGradient(
            colors: [accent, accent.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let cardGradient = LinearGradient(
            colors: [
                Color.black.opacity(0),
                Color.black.opacity(0.3),
                Color.black.opacity(0.7)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        static let thumbnailGradient = LinearGradient(
            colors: [
                surfaceElevatedFallback,
                surfaceFallback
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Shadows

    struct Shadows {
        static let subtle = Color.black.opacity(0.15)
        static let medium = Color.black.opacity(0.25)
        static let prominent = Color.black.opacity(0.4)

        static let cardShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - View Modifiers

extension View {
    func resurfaceCard() -> some View {
        self
            .background(ResurfaceTheme.Colors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium)
                    .stroke(ResurfaceTheme.Colors.border, lineWidth: 1)
            )
    }

    func resurfaceSurface() -> some View {
        self
            .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.small))
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Color swatches
            HStack(spacing: 12) {
                colorSwatch("BG", ResurfaceTheme.Colors.backgroundFallback)
                colorSwatch("Surface", ResurfaceTheme.Colors.surfaceFallback)
                colorSwatch("Elevated", ResurfaceTheme.Colors.surfaceElevatedFallback)
                colorSwatch("Accent", ResurfaceTheme.Colors.accent)
            }

            HStack(spacing: 12) {
                colorSwatch("Text 1", ResurfaceTheme.Colors.textPrimary)
                colorSwatch("Text 2", ResurfaceTheme.Colors.textSecondary)
                colorSwatch("Text 3", ResurfaceTheme.Colors.textTertiary)
                colorSwatch("Border", ResurfaceTheme.Colors.border)
            }

            HStack(spacing: 12) {
                colorSwatch("Success", ResurfaceTheme.Colors.success)
                colorSwatch("Warning", ResurfaceTheme.Colors.warning)
                colorSwatch("Error", ResurfaceTheme.Colors.error)
            }

            // Sample card
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample Card")
                    .font(.headline)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                Text("This is how cards will look")
                    .font(.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .resurfaceCard()
        }
        .padding()
    }
    .background(ResurfaceTheme.Colors.backgroundFallback)
}

private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 60, height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        Text(name)
            .font(.caption2)
            .foregroundStyle(.white)
    }
}
