//
//  SharedDataManager.swift
//  DNSGuard
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Synchronizes telemetry, preferences, and server configurations between Main App and Extension.
//

import Foundation
import Combine

public final class SharedDataManager: ObservableObject {
    
    public static let shared = SharedDataManager()
    
    @Published public var totalQueries: Int = 0
    @Published public var cacheHits: Int = 0
    @Published public var repairedChecksums: Int = 0
    @Published public var healedTruncations: Int = 0
    @Published public var averageLatency: Double = 0.0
    @Published public var currentStrategy: LoadBalancingStrategy = .racing
    
    public var cacheHitRate: Double {
        guard totalQueries > 0 else { return 0.0 }
        return (Double(cacheHits) / Double(totalQueries)) * 100.0
    }
    
    public var totalRepairs: Int {
        return repairedChecksums + healedTruncations
    }
    
    private var timer: Timer?
    
    private init() {
        loadSettings()
        startPollingTelemetry()
    }
    
    public func startPollingTelemetry() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshTelemetry()
        }
    }
    
    public func refreshTelemetry() {
        guard let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.appGroupId) else { return }
        
        DispatchQueue.main.async {
            self.totalQueries = sharedDefaults.integer(forKey: AppGroupConstants.keyTotalQueries)
            self.cacheHits = sharedDefaults.integer(forKey: AppGroupConstants.keyCacheHits)
            self.repairedChecksums = sharedDefaults.integer(forKey: AppGroupConstants.keyRepairedChecksums)
            self.healedTruncations = sharedDefaults.integer(forKey: AppGroupConstants.keyHealedTruncations)
            self.averageLatency = sharedDefaults.double(forKey: AppGroupConstants.keyAverageLatency)
        }
    }
    
    public func updateStrategy(_ strategy: LoadBalancingStrategy) {
        self.currentStrategy = strategy
        guard let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.appGroupId) else { return }
        sharedDefaults.set(strategy.rawValue, forKey: AppGroupConstants.keyLoadBalancingStrategy)
    }
    
    private func loadSettings() {
        guard let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.appGroupId) else { return }
        if let raw = sharedDefaults.string(forKey: AppGroupConstants.keyLoadBalancingStrategy),
           let strat = LoadBalancingStrategy(rawValue: raw) {
            self.currentStrategy = strat
        }
    }
}
