//
//  DNSQueryLog.swift
//  DNSGuard
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Represents a logged DNS transaction for inspection, telemetry, and debugging.
//

import Foundation

public struct DNSQueryLog: Identifiable, Codable {
    public var id: String
    public var domain: String
    public var recordType: String
    public var serverUsed: String
    public var latencyMs: Double
    public var timestamp: Date
    public var isCached: Bool
    public var isRepaired: Bool
    public var repairReason: String?
    public var strategy: String?
    public var resolvedIP: String?
    
    public init(id: String = UUID().uuidString,
                domain: String,
                recordType: String = "A",
                serverUsed: String,
                latencyMs: Double,
                timestamp: Date = Date(),
                isCached: Bool = false,
                isRepaired: Bool = false,
                repairReason: String? = nil,
                strategy: String? = nil,
                resolvedIP: String? = nil) {
        self.id = id
        self.domain = domain
        self.recordType = recordType
        self.serverUsed = serverUsed
        self.latencyMs = latencyMs
        self.timestamp = timestamp
        self.isCached = isCached
        self.isRepaired = isRepaired
        self.repairReason = repairReason
        self.strategy = strategy
        self.resolvedIP = resolvedIP
    }
}
