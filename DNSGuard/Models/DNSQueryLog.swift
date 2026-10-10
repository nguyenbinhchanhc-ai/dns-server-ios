//
//  DNSQueryLog.swift
//  DNSGuard
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Represents a logged DNS transaction for inspection, telemetry, and debugging.
//  Equipped with Color Tagging and QoS Priority Tiering (P0 - P3).
//

import Foundation
import SwiftUI

public struct DNSQueryLog: Identifiable, Codable {
    public var id: String
    public var domain: String
    public var recordType: String
    public var serverUsed: String
    public var serverColorHex: String
    public var priorityTier: String // "P0", "P1", "P2", "P3"
    public var priorityColorHex: String
    public var latencyMs: Double
    public var timestamp: Date
    public var isCached: Bool
    public var isRepaired: Bool
    public var repairReason: String?
    public var strategy: String?
    public var resolvedIP: String?
    
    public var priorityTitle: String {
        switch priorityTier {
        case "P0": return "P0 Khẩn cấp"
        case "P1": return "P1 Ưu tiên cao"
        case "P2": return "P2 Tiêu chuẩn"
        case "P3": return "P3 Lọc rác"
        default: return "P2 Tiêu chuẩn"
        }
    }
    
    public init(id: String = UUID().uuidString,
                domain: String,
                recordType: String = "A",
                serverUsed: String,
                serverColorHex: String = "#007AFF",
                priorityTier: String = "P2",
                priorityColorHex: String = "#007AFF",
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
        self.serverColorHex = serverColorHex
        self.priorityTier = priorityTier
        self.priorityColorHex = priorityColorHex
        self.latencyMs = latencyMs
        self.timestamp = timestamp
        self.isCached = isCached
        self.isRepaired = isRepaired
        self.repairReason = repairReason
        self.strategy = strategy
        self.resolvedIP = resolvedIP
    }
    
    // Custom Decodable to support backward compatibility with old logs
    enum CodingKeys: String, CodingKey {
        case id, domain, recordType, serverUsed, serverColorHex, priorityTier, priorityColorHex
        case latencyMs, timestamp, isCached, isRepaired, repairReason, strategy, resolvedIP
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        domain = try container.decodeIfPresent(String.self, forKey: .domain) ?? ""
        recordType = try container.decodeIfPresent(String.self, forKey: .recordType) ?? "A"
        serverUsed = try container.decodeIfPresent(String.self, forKey: .serverUsed) ?? "Cloudflare"
        serverColorHex = try container.decodeIfPresent(String.self, forKey: .serverColorHex) ?? "#007AFF"
        priorityTier = try container.decodeIfPresent(String.self, forKey: .priorityTier) ?? "P2"
        priorityColorHex = try container.decodeIfPresent(String.self, forKey: .priorityColorHex) ?? "#007AFF"
        latencyMs = try container.decodeIfPresent(Double.self, forKey: .latencyMs) ?? 15.0
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        isCached = try container.decodeIfPresent(Bool.self, forKey: .isCached) ?? false
        isRepaired = try container.decodeIfPresent(Bool.self, forKey: .isRepaired) ?? false
        repairReason = try container.decodeIfPresent(String.self, forKey: .repairReason)
        strategy = try container.decodeIfPresent(String.self, forKey: .strategy)
        resolvedIP = try container.decodeIfPresent(String.self, forKey: .resolvedIP)
    }
}

// MARK: - Color Hex Initializer Extension
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
