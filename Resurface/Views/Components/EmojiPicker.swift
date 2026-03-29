import SwiftUI

/// Grid-based emoji picker with common emoji categories
struct EmojiPicker: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss

    /// Common emojis organized by rough category
    private let emojis: [String] = [
        // Objects & Organization
        "📁", "📂", "🗂️", "📋", "📝", "📌", "📎", "🔖", "🏷️", "📦",
        // Money & Finance
        "💰", "💵", "💳", "🧾", "📊", "📈", "🏦", "💎", "🪙", "💸",
        // Health & Wellness
        "🏥", "💊", "🩺", "🏃", "🧘", "🍎", "💪", "🧠", "❤️", "🩹",
        // Food & Drink
        "🍕", "🍔", "🍣", "🍜", "🥗", "☕", "🍷", "🍰", "🥘", "🌮",
        // Travel & Places
        "✈️", "🏖️", "🗺️", "🧳", "🏨", "⛰️", "🚗", "🚀", "🏠", "🌍",
        // Ideas & Creativity
        "💡", "🎨", "✨", "🎯", "🔮", "🎭", "📸", "🎬", "🎵", "🎤",
        // People & Social
        "👥", "💬", "❤️‍🔥", "🎁", "🎂", "👨‍👩‍👧", "🤝", "💌", "🎉", "🥂",
        // Work & Productivity
        "💼", "📅", "⏰", "✅", "🎓", "📚", "🔧", "⚙️", "🛠️", "📱",
        // Nature & Misc
        "🌱", "🌸", "🐕", "☀️", "🌙", "⭐", "🔥", "💧", "🌈", "🎀"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                            dismiss()
                        } label: {
                            Text(emoji)
                                .font(.system(size: 32))
                                .frame(width: 50, height: 50)
                                .background(
                                    selectedEmoji == emoji
                                        ? ResurfaceTheme.Colors.accent.opacity(0.3)
                                        : ResurfaceTheme.Colors.surfaceElevatedFallback
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            selectedEmoji == emoji
                                                ? ResurfaceTheme.Colors.accent
                                                : ResurfaceTheme.Colors.border,
                                            lineWidth: selectedEmoji == emoji ? 2 : 0.5
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                }
            }
            .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

/// Compact emoji button that opens the picker
struct EmojiPickerButton: View {
    @Binding var selectedEmoji: String
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            Text(selectedEmoji)
                .font(.system(size: 48))
                .frame(width: 80, height: 80)
                .background(ResurfaceTheme.Colors.surfaceElevatedFallback)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ResurfaceTheme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            EmojiPicker(selectedEmoji: $selectedEmoji)
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var emoji = "📁"

        var body: some View {
            VStack(spacing: 20) {
                EmojiPickerButton(selectedEmoji: $emoji)

                Text("Selected: \(emoji)")
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ResurfaceTheme.Colors.backgroundFallback)
        }
    }

    return PreviewWrapper()
}
