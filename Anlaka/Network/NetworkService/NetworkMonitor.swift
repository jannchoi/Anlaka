//
//  NetworkMonitor.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Network
import Foundation

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Monitor")

    private(set) var isConnected: Bool = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }

    func checkConnection() async throws {
        if !isConnected {
            throw CustomError.disconnected
        }
    }

    func observeStatus() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied)
            }
        }
    }
}

