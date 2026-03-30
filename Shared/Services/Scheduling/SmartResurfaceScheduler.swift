import Foundation

/// Computes smart resurface dates based on content type and AI suggestions
enum SmartResurfaceScheduler {

    /// Suggest a resurface date based on content type, AI suggestion, and category
    static func suggestedDate(
        for contentType: ContentType,
        contentSubtype: String?,
        category: Category?,
        aiSuggestedDays: Int?
    ) -> Date? {
        // Skip scheduling for categories that don't show in feed
        if category?.showInFeed == false {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()

        // Priority 1: AI suggestion
        if let days = aiSuggestedDays, days > 0 {
            let target = calendar.date(byAdding: .day, value: days, to: now)!
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: target)
        }

        // Priority 2: Content-type heuristic
        return heuristicDate(for: contentType, now: now, calendar: calendar)
    }

    /// Apply backoff when user dismisses: double the interval each time, minimum 1 day
    static func backoffDate(dismissCount: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let baseDays = max(1, Int(pow(2.0, Double(dismissCount))))
        let target = calendar.date(byAdding: .day, value: baseDays, to: now)!
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: target)!
    }

    // MARK: - Private

    private static func heuristicDate(
        for contentType: ContentType,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        switch contentType {
        case .article:
            // Long article → this weekend
            return nextWeekend(from: now, calendar: calendar)

        case .youtube, .video:
            // Video → 3 days
            let target = calendar.date(byAdding: .day, value: 3, to: now)!
            return calendar.date(bySettingHour: 19, minute: 0, second: 0, of: target)

        case .image, .screenshot:
            // Visual inspiration → 2 weeks
            let target = calendar.date(byAdding: .day, value: 14, to: now)!
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: target)

        case .pdf:
            // Reference material → 1 month
            let target = calendar.date(byAdding: .month, value: 1, to: now)!
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: target)

        case .socialPost:
            // News/social → stale quickly, no auto-resurface
            return nil

        case .url, .text, .file, .unknown:
            // Generic → 1 week
            let target = calendar.date(byAdding: .day, value: 7, to: now)!
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: target)
        }
    }

    private static func nextWeekend(from date: Date, calendar: Calendar) -> Date? {
        let weekday = calendar.component(.weekday, from: date)
        // Saturday = 7, Sunday = 1
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let saturday = calendar.date(
            byAdding: .day,
            value: daysUntilSaturday == 0 ? 7 : daysUntilSaturday,
            to: date
        )!
        return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: saturday)
    }
}
