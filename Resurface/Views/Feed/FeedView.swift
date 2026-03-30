import SwiftUI
import SwiftData

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var resurfaceEngine = ResurfaceEngine.shared

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
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
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
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("\(resurfaceEngine.todayItems.count) to revisit")
                        .font(Typography.subheadline)
                        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                }

                Spacer()

                Button {
                    resurfaceEngine.refreshFeed(in: modelContext)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.layout.horizontalPadding)
            .padding(.top, Spacing.sm)

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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: 100)

            Image(systemName: "checkmark.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(ResurfaceTheme.Colors.success)

            VStack(spacing: Spacing.xs) {
                Text("All caught up!")
                    .font(Typography.title3)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                Text("No items to resurface right now.\nSave content and it will appear here when it's time to revisit.")
                    .font(Typography.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
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
