//
//  AppGroupConstants.swift
//  DNSGuard
//
//  Shared constants across App and NetworkExtension targets.
//

import Foundation

public struct AppGroupConstants {
    public static let appGroupId = "group.com.antigravity.dnsguard"
    public static let tunnelBundleId = "com.antigravity.dnsguard.tunnel"
    public static let mainAppBundleId = "com.antigravity.dnsguard"
    
    // UserDefaults Keys
    public static let keyIsVPNEnabled = "isVPNEnabled"
    public static let keyLoadBalancingStrategy = "loadBalancingStrategy"
    public static let keyTotalQueries = "totalQueries"
    public static let keyCacheHits = "cacheHits"
    public static let keyRepairedChecksums = "repairedChecksums"
    public static let keyHealedTruncations = "healedTruncations"
    public static let keyAverageLatency = "averageLatency"
    public static let keyServersList = "customServersList"
}
