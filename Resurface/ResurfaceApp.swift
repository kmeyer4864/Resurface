//
//  ResurfaceApp.swift
//  Resurface
//
//  Created by Keenan Meyer on 3/26/26.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct ResurfaceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BookmarkItem.self,
            Category.self,
            Tag.self,
            WebContent.self,
        ])

        // Use App Group container for shared storage with Share Extension
        let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.keenanmeyer.resurface"
        )
        let storeURL = appGroupURL?.appendingPathComponent("default.store")

        let modelConfiguration: ModelConfiguration
        if let storeURL = storeURL {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                allowsSave: true
            )
        } else {
            // Fallback to default location if App Group not available
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Migration failed — delete old store and retry with fresh database
            print("Unresolved error loading container \(error)")
            if let storeURL = storeURL {
                let fileManager = FileManager.default
                // Remove all SwiftData store files
                let storeFiles = [
                    storeURL,
                    storeURL.appendingPathExtension("wal"),
                    storeURL.appendingPathExtension("shm"),
                ]
                for file in storeFiles {
                    try? fileManager.removeItem(at: file)
                }
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }()

    /// Observer for Share Extension notifications
    @State private var shareNotificationObserver: NSObjectProtocol?

    /// Observer for network connectivity changes
    @State private var networkObserver: NSObjectProtocol?

    /// Deep link navigation state
    @State private var showCreateCategory = false
    @State private var deepLinkItemId: UUID?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupServices()
                }
                .task {
                    await processOnLaunch()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    Task {
                        await processOnActivate()
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .sheet(isPresented: $showCreateCategory) {
                    CategoryCreationView()
                }
                .environment(\.openItemId, deepLinkItemId)
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Service Setup

    /// Initialize background services
    private func setupServices() {
        // Start network monitoring
        NetworkMonitor.shared.start()

        // Observe Share Extension notifications
        shareNotificationObserver = ShareNotification.observeNewContent { [self] in
            Task { @MainActor in
                await processPendingItems()
            }
        }

        // Observe network connectivity changes - retry AI processing when coming back online
        networkObserver = NotificationCenter.default.addObserver(
            forName: NetworkMonitor.connectivityChangedNotification,
            object: nil,
            queue: .main
        ) { [self] notification in
            guard let isConnected = notification.userInfo?["isConnected"] as? Bool,
                  isConnected else { return }

            // Network came back - retry AI processing
            Task { @MainActor in
                let context = sharedModelContainer.mainContext
                await BackgroundProcessor.shared.retryAIProcessing(in: context)
            }
        }

        // Set up notification delegate
        appDelegate.modelContainer = sharedModelContainer
    }

    // MARK: - Background Processing

    /// Process pending items on app launch
    @MainActor
    private func processOnLaunch() async {
        let context = sharedModelContainer.mainContext

        // Seed categories on first launch
        CategorySeeder.shared.seedCategoriesIfNeeded(in: context)

        // Process pending items
        await processPendingItems()

        // Schedule any pending resurface notifications
        await scheduleResurfaceNotifications(in: context)
    }

    /// Process pending items when app becomes active
    @MainActor
    private func processOnActivate() async {
        // Small delay to let UI settle
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        await processPendingItems()

        // Retry AI processing for items that need it
        let context = sharedModelContainer.mainContext
        await BackgroundProcessor.shared.retryAIProcessing(in: context)
    }

    /// Process all pending bookmark items
    @MainActor
    private func processPendingItems() async {
        let context = sharedModelContainer.mainContext
        await BackgroundProcessor.shared.processPendingItems(in: context)
    }

    /// Schedule notifications for items that need them
    @MainActor
    private func scheduleResurfaceNotifications(in context: ModelContext) async {
        // Find items with resurface dates but no notification ID
        let descriptor = FetchDescriptor<BookmarkItem>(
            predicate: #Predicate<BookmarkItem> { item in
                item.resurfaceAt != nil && item.resurfaceNotificationId == nil
            }
        )

        guard let items = try? context.fetch(descriptor) else { return }

        for item in items {
            guard let resurfaceAt = item.resurfaceAt else { continue }

            let notificationId = await ResurfaceNotificationService.shared.scheduleNotification(
                for: item.id,
                title: item.displayTitle,
                at: resurfaceAt
            )

            if let notificationId = notificationId {
                item.resurfaceNotificationId = notificationId
            }
        }

        try? context.save()
    }

    // MARK: - Deep Links

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "resurface" else { return }

        switch url.host {
        case "create-category":
            showCreateCategory = true

        case "item":
            // resurface://item?id=UUID
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let id = UUID(uuidString: idString) {
                deepLinkItemId = id
            }

        default:
            break
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var modelContainer: ModelContainer?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let itemId = await ResurfaceNotificationService.shared.extractItemId(from: response) else {
            return
        }

        // Handle snooze action
        if await ResurfaceNotificationService.shared.isSnoozeAction(response) {
            await handleSnooze(itemId: itemId)
            return
        }

        // Navigate to item
        await MainActor.run {
            // Post notification to navigate to item
            NotificationCenter.default.post(
                name: .openBookmarkItem,
                object: nil,
                userInfo: ["itemId": itemId]
            )
        }
    }

    private func handleSnooze(itemId: UUID) async {
        guard let container = modelContainer else { return }

        await MainActor.run {
            let context = container.mainContext
            let descriptor = FetchDescriptor<BookmarkItem>(
                predicate: #Predicate<BookmarkItem> { $0.id == itemId }
            )

            guard let item = try? context.fetch(descriptor).first else { return }

            // Reschedule for tomorrow
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let tomorrowNineAM = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!

            item.resurfaceAt = tomorrowNineAM

            Task {
                let notificationId = await ResurfaceNotificationService.shared.scheduleNotification(
                    for: item.id,
                    title: item.displayTitle,
                    at: tomorrowNineAM
                )
                await MainActor.run {
                    item.resurfaceNotificationId = notificationId
                    try? context.save()
                }
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openBookmarkItem = Notification.Name("openBookmarkItem")
}

// MARK: - Environment Keys

private struct OpenItemIdKey: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

extension EnvironmentValues {
    var openItemId: UUID? {
        get { self[OpenItemIdKey.self] }
        set { self[OpenItemIdKey.self] = newValue }
    }
}
