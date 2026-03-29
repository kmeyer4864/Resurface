import Foundation

/// Options for when to resurface (notify about) saved content
enum ResurfaceOption: String, Codable, CaseIterable, Identifiable {
    case never
    case laterToday
    case tomorrow
    case nextWeek
    case nextMonth
    case nextYear

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .never: return "Never"
        case .laterToday: return "Later Today"
        case .tomorrow: return "Tomorrow"
        case .nextWeek: return "Next Week"
        case .nextMonth: return "Next Month"
        case .nextYear: return "Next Year"
        }
    }

    var shortName: String {
        switch self {
        case .never: return "Never"
        case .laterToday: return "Today"
        case .tomorrow: return "Tomorrow"
        case .nextWeek: return "1 Week"
        case .nextMonth: return "1 Month"
        case .nextYear: return "1 Year"
        }
    }

    var iconName: String {
        switch self {
        case .never: return "bell.slash"
        case .laterToday: return "clock"
        case .tomorrow: return "sunrise"
        case .nextWeek: return "calendar"
        case .nextMonth: return "calendar.badge.clock"
        case .nextYear: return "calendar.circle"
        }
    }

    /// Calculate the target date for resurfacing from a given start date
    /// Returns nil for .never
    func targetDate(from startDate: Date = Date()) -> Date? {
        let calendar = Calendar.current

        switch self {
        case .never:
            return nil

        case .laterToday:
            // 6 hours from now, but not past 9 PM
            let sixHoursLater = calendar.date(byAdding: .hour, value: 6, to: startDate)!
            let ninePM = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: startDate)!

            if sixHoursLater > ninePM {
                // If 6 hours would be past 9 PM, schedule for tomorrow 9 AM instead
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: startDate)!)
            }
            return sixHoursLater

        case .tomorrow:
            // Tomorrow at 9 AM
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: startDate)!
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)

        case .nextWeek:
            // 7 days from now at 9 AM
            let nextWeek = calendar.date(byAdding: .day, value: 7, to: startDate)!
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextWeek)

        case .nextMonth:
            // 30 days from now at 9 AM
            let nextMonth = calendar.date(byAdding: .day, value: 30, to: startDate)!
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextMonth)

        case .nextYear:
            // 365 days from now at 9 AM
            let nextYear = calendar.date(byAdding: .day, value: 365, to: startDate)!
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextYear)
        }
    }

    /// Human-readable description of when this will resurface
    func relativeDescription(from startDate: Date = Date()) -> String? {
        guard let target = targetDate(from: startDate) else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: target, relativeTo: startDate)
    }
}
