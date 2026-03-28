import Foundation
import Network

/// Monitors network connectivity status
@Observable
final class NetworkMonitor {
    /// Shared instance
    static let shared = NetworkMonitor()

    /// Whether the device is connected to the network
    private(set) var isConnected: Bool = true

    /// Whether the connection is expensive (cellular, hotspot)
    private(set) var isExpensive: Bool = false

    /// Whether the connection is constrained (Low Data Mode)
    private(set) var isConstrained: Bool = false

    /// The current connection type
    private(set) var connectionType: ConnectionType = .unknown

    /// Connection type
    enum ConnectionType: String {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.resurface.networkmonitor", qos: .utility)

    private init() {
        monitor = NWPathMonitor()
    }

    /// Start monitoring network changes
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateStatus(with: path)
            }
        }
        monitor.start(queue: queue)
    }

    /// Stop monitoring network changes
    func stop() {
        monitor.cancel()
    }

    /// Update status based on NWPath
    @MainActor
    private func updateStatus(with path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = .unknown
        }
    }

    /// Wait for network to become available
    /// - Parameter timeout: Maximum time to wait (default: 30 seconds)
    /// - Returns: true if network became available, false if timeout
    func waitForConnection(timeout: TimeInterval = 30) async -> Bool {
        if isConnected { return true }

        let startTime = Date()

        while !isConnected {
            if Date().timeIntervalSince(startTime) > timeout {
                return false
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        return true
    }
}

// MARK: - Notification Extension

extension NetworkMonitor {
    /// Notification posted when network connectivity changes
    static let connectivityChangedNotification = Notification.Name("com.resurface.network.connectivityChanged")

    /// Post notification when connectivity changes
    @MainActor
    func postConnectivityNotification() {
        NotificationCenter.default.post(
            name: Self.connectivityChangedNotification,
            object: nil,
            userInfo: ["isConnected": isConnected]
        )
    }
}
