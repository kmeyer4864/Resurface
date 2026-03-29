import Foundation
import UserNotifications

/// Manages local notifications for resurfacing saved content
actor ResurfaceNotificationService {
    /// Shared instance
    static let shared = ResurfaceNotificationService()

    /// Notification category identifier
    private let categoryIdentifier = "RESURFACE_REMINDER"

    /// Action identifiers
    private let openActionIdentifier = "OPEN_ACTION"
    private let snoozeActionIdentifier = "SNOOZE_ACTION"

    private init() {}

    // MARK: - Permission

    /// Request notification permission
    /// - Returns: True if permission granted
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

            if granted {
                await setupNotificationCategories()
            }

            return granted
        } catch {
            return false
        }
    }

    /// Check current authorization status
    func checkPermission() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Scheduling

    /// Schedule a resurface notification for a bookmark item
    /// - Parameters:
    ///   - item: The bookmark item to resurface
    ///   - at: The date/time to show the notification
    /// - Returns: The notification identifier, or nil if scheduling failed
    func scheduleNotification(for itemId: UUID, title: String, at date: Date) async -> String? {
        let center = UNUserNotificationCenter.current()

        // Check permission
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            return nil
        }

        // Don't schedule for past dates
        guard date > Date() else {
            return nil
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to resurface!"
        content.body = title.count > 100 ? String(title.prefix(97)) + "..." : title
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = ["itemId": itemId.uuidString]

        // Create trigger
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create request
        let identifier = "resurface-\(itemId.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            return identifier
        } catch {
            return nil
        }
    }

    /// Cancel a scheduled notification
    /// - Parameter identifier: The notification identifier to cancel
    func cancelNotification(identifier: String) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all resurface notifications for an item
    /// - Parameter itemId: The bookmark item ID
    func cancelNotifications(for itemId: UUID) async {
        let identifier = "resurface-\(itemId.uuidString)"
        await cancelNotification(identifier: identifier)
    }

    /// Reschedule a notification (cancel old, create new)
    /// - Parameters:
    ///   - itemId: The bookmark item ID
    ///   - title: The item title
    ///   - at: New date/time
    /// - Returns: New notification identifier
    func rescheduleNotification(for itemId: UUID, title: String, at date: Date) async -> String? {
        await cancelNotifications(for: itemId)
        return await scheduleNotification(for: itemId, title: title, at: date)
    }

    // MARK: - Setup

    /// Set up notification categories with actions
    private func setupNotificationCategories() async {
        let center = UNUserNotificationCenter.current()

        // Open action
        let openAction = UNNotificationAction(
            identifier: openActionIdentifier,
            title: "Open",
            options: .foreground
        )

        // Snooze action (reschedule for tomorrow)
        let snoozeAction = UNNotificationAction(
            identifier: snoozeActionIdentifier,
            title: "Remind Tomorrow",
            options: []
        )

        // Create category
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [openAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }

    // MARK: - Utilities

    /// Get all pending resurface notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        return pending.filter { $0.identifier.hasPrefix("resurface-") }
    }

    /// Extract item ID from a notification
    func extractItemId(from notification: UNNotification) -> UUID? {
        guard let idString = notification.request.content.userInfo["itemId"] as? String else {
            return nil
        }
        return UUID(uuidString: idString)
    }

    /// Extract item ID from notification response
    func extractItemId(from response: UNNotificationResponse) -> UUID? {
        guard let idString = response.notification.request.content.userInfo["itemId"] as? String else {
            return nil
        }
        return UUID(uuidString: idString)
    }

    /// Check if response is a snooze action
    func isSnoozeAction(_ response: UNNotificationResponse) -> Bool {
        return response.actionIdentifier == snoozeActionIdentifier
    }
}
