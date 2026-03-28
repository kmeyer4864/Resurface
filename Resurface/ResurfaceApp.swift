//
//  ResurfaceApp.swift
//  Resurface
//
//  Created by Keenan Meyer on 3/26/26.
//

import SwiftUI
import SwiftData

@main
struct ResurfaceApp: App {
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
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// Observer for Share Extension notifications
    @State private var shareNotificationObserver: NSObjectProtocol?

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
    }

    // MARK: - Background Processing

    /// Process pending items on app launch
    @MainActor
    private func processOnLaunch() async {
        await processPendingItems()
    }

    /// Process pending items when app becomes active
    @MainActor
    private func processOnActivate() async {
        // Small delay to let UI settle
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        await processPendingItems()
    }

    /// Process all pending bookmark items
    @MainActor
    private func processPendingItems() async {
        let context = sharedModelContainer.mainContext
        await BackgroundProcessor.shared.processPendingItems(in: context)
    }
}
