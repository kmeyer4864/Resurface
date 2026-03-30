import Foundation
import SwiftData

/// Selects items to resurface in the "Today" feed
@Observable
@MainActor
final class ResurfaceEngine {

    static let shared = ResurfaceEngine()

    /// Items to show in today's feed
    private(set) var todayItems: [ResurfaceItem] = []

    private init() {}

    // MARK: - Types

    struct ResurfaceItem: Identifiable {
        let id: UUID
        let item: BookmarkItem
        let reason: ResurfaceReason
    }

    enum ResurfaceReason {
        case scheduled
        case neverViewed
        case serendipity

        var label: String {
            switch self {
            case .scheduled: return "Scheduled for today"
            case .neverViewed: return "You haven't looked at this yet"
            case .serendipity: return "From your archive"
            }
        }

        var icon: String {
            switch self {
            case .scheduled: return "bell.fill"
            case .neverViewed: return "eye.slash"
            case .serendipity: return "sparkles"
            }
        }
    }

    // MARK: - Public API

    /// Refresh the feed with items to resurface today
    func refreshFeed(in context: ModelContext) {
        var candidates: [ResurfaceItem] = []
        var seen = Set<UUID>()
        let now = Date()

        // 1. Scheduled items (resurfaceAt <= now, not dismissed recently)
        candidates.append(contentsOf: fetchScheduledItems(before: now, in: context, seen: &seen))

        // 2. Never-viewed items (saved > 3 days ago)
        candidates.append(contentsOf: fetchNeverViewedItems(before: now, in: context, seen: &seen))

        // 3. Serendipity picks (random from items > 2 weeks old)
        candidates.append(contentsOf: fetchSerendipityItems(before: now, in: context, seen: &seen))

        // Cap at 5
        todayItems = Array(candidates.prefix(5))
    }

    /// Dismiss an item from the feed with backoff
    func dismiss(_ item: BookmarkItem, in context: ModelContext) {
        item.resurfaceDismissedAt = Date()
        item.resurfaceDismissCount += 1

        // Reschedule with backoff
        item.resurfaceAt = SmartResurfaceScheduler.backoffDate(dismissCount: item.resurfaceDismissCount)

        item.markUpdated()
        try? context.save()
        todayItems.removeAll { $0.id == item.id }
    }

    /// Snooze an item until a specific date
    func snooze(_ item: BookmarkItem, until date: Date, in context: ModelContext) {
        item.resurfaceAt = date
        item.resurfaceDismissedAt = nil
        item.markUpdated()
        try? context.save()
        todayItems.removeAll { $0.id == item.id }
    }

    // MARK: - Private Fetchers

    private func fetchScheduledItems(
        before now: Date,
        in context: ModelContext,
        seen: inout Set<UUID>
    ) -> [ResurfaceItem] {
        let descriptor = FetchDescriptor<BookmarkItem>(
            predicate: #Predicate<BookmarkItem> {
                $0.resurfaceAt != nil && !$0.isArchived
            },
            sortBy: [SortDescriptor(\.resurfaceAt, order: .forward)]
        )

        guard let items = try? context.fetch(descriptor) else { return [] }

        var results: [ResurfaceItem] = []
        for item in items {
            guard let resurfaceAt = item.resurfaceAt,
                  resurfaceAt <= now,
                  !isDismissedRecently(item),
                  seen.insert(item.id).inserted else { continue }
            results.append(ResurfaceItem(id: item.id, item: item, reason: .scheduled))
        }
        return results
    }

    private func fetchNeverViewedItems(
        before now: Date,
        in context: ModelContext,
        seen: inout Set<UUID>
    ) -> [ResurfaceItem] {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!

        let descriptor = FetchDescriptor<BookmarkItem>(
            predicate: #Predicate<BookmarkItem> {
                $0.lastViewedAt == nil && !$0.isArchived && $0.createdAt < threeDaysAgo
            }
        )

        guard let items = try? context.fetch(descriptor) else { return [] }

        var results: [ResurfaceItem] = []
        for item in items.shuffled().prefix(2) {
            guard seen.insert(item.id).inserted else { continue }
            results.append(ResurfaceItem(id: item.id, item: item, reason: .neverViewed))
        }
        return results
    }

    private func fetchSerendipityItems(
        before now: Date,
        in context: ModelContext,
        seen: inout Set<UUID>
    ) -> [ResurfaceItem] {
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now)!

        let descriptor = FetchDescriptor<BookmarkItem>(
            predicate: #Predicate<BookmarkItem> {
                !$0.isArchived && $0.createdAt < twoWeeksAgo
            }
        )

        guard let items = try? context.fetch(descriptor) else { return [] }

        var results: [ResurfaceItem] = []
        for item in items.shuffled().prefix(1) {
            guard seen.insert(item.id).inserted else { continue }
            results.append(ResurfaceItem(id: item.id, item: item, reason: .serendipity))
        }
        return results
    }

    private func isDismissedRecently(_ item: BookmarkItem) -> Bool {
        guard let dismissedAt = item.resurfaceDismissedAt else { return false }
        // Consider "recently" as within the last hour
        return dismissedAt.timeIntervalSinceNow > -3600
    }
}
