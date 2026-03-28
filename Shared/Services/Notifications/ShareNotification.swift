import Foundation

/// Handles Darwin notifications for cross-process communication between Share Extension and main app
enum ShareNotification {
    /// Notification identifier for new content saved
    static let newContentIdentifier = "com.keenanmeyer.resurface.newContent" as CFString

    /// Post notification that new content was saved by Share Extension
    static func postNewContent() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(newContentIdentifier),
            nil,
            nil,
            true
        )
    }

    /// Observe notifications for new content
    /// - Parameter handler: Called when new content notification is received
    /// - Returns: Observer token to store (observation stops when token is deallocated)
    static func observeNewContent(handler: @escaping () -> Void) -> NSObjectProtocol {
        let observer = DarwinNotificationObserver(name: newContentIdentifier, handler: handler)
        observer.startObserving()
        return observer
    }
}

/// Helper class for observing Darwin notifications
private class DarwinNotificationObserver: NSObject {
    private let name: CFString
    private let handler: () -> Void
    private var isObserving = false

    init(name: CFString, handler: @escaping () -> Void) {
        self.name = name
        self.handler = handler
        super.init()
    }

    deinit {
        stopObserving()
    }

    func startObserving() {
        guard !isObserving else { return }

        let callback: CFNotificationCallback = { _, observer, _, _, _ in
            guard let observer = observer else { return }
            let this = Unmanaged<DarwinNotificationObserver>.fromOpaque(observer).takeUnretainedValue()
            DispatchQueue.main.async {
                this.handler()
            }
        }

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            callback,
            name,
            nil,
            .deliverImmediately
        )

        isObserving = true
    }

    func stopObserving() {
        guard isObserving else { return }

        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(name),
            nil
        )

        isObserving = false
    }
}
