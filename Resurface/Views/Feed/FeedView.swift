import SwiftUI
import SwiftData

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var resurfaceEngine = ResurfaceEngine.shared

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Late night"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if resurfaceEngine.todayItems.isEmpty {
                    emptyState
                } else {
                    feedContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                resurfaceEngine.refreshFeed(in: modelContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                resurfaceEngine.refreshFeed(in: modelContext)
            }
        }
    }

    // MARK: - Feed Content

    private var feedContent: some View {
        LazyVStack(spacing: Spacing.md) {
            // Header
            feedHeader

            // Cards
            ForEach(resurfaceEngine.todayItems) { resurfaceItem in
                NavigationLink(destination: BookmarkDetailView(item: resurfaceItem.item)) {
                    ResurfaceCard(
                        resurfaceItem: resurfaceItem,
                        onDismiss: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                resurfaceEngine.dismiss(resurfaceItem.item, in: modelContext)
                            }
                        },
                        onSnooze: {
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                            let morning = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
                            withAnimation(.easeInOut(duration: 0.3)) {
                                resurfaceEngine.snooze(resurfaceItem.item, until: morning, in: modelContext)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.layout.horizontalPadding)
            }

            Spacer(minLength: Spacing.xxxl)
        }
    }

    // MARK: - Feed Header

    private var feedHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(greeting)
                .font(Typography.title2)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

            HStack {
                Text(dateString)
                    .font(Typography.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)

                Spacer()

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(ResurfaceTheme.Colors.accent)
                    Text("\(resurfaceEngine.todayItems.count) to revisit")
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                }

                Button {
                    resurfaceEngine.refreshFeed(in: modelContext)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.layout.horizontalPadding)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xs)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: 120)

            // Zen circle
            ZStack {
                Circle()
                    .stroke(ResurfaceTheme.Colors.accent.opacity(0.2), lineWidth: 2)
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(ResurfaceTheme.Colors.accent)
            }

            VStack(spacing: Spacing.xs) {
                Text("You're all caught up")
                    .font(Typography.title3)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                Text("Nothing to resurface right now.\nNew items will appear as they're ready.")
                    .font(Typography.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.layout.horizontalPadding)
    }
}

#Preview {
    FeedView()
        .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
        .preferredColorScheme(.dark)
}
