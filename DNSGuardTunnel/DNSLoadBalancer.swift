//
//  DNSLoadBalancer.swift
//  DNSGuardTunnel
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Dynamic load balancer & health monitor across upstream DNS providers.
//

import Foundation

public enum LoadBalancingStrategy: String, CaseIterable, Codable {
    case racing = "Racing (Fastest Response)"
    case weightedLatency = "Weighted Latency (EWMA)"
    case fastest = "Lowest Latency"
    case roundRobin = "Round Robin"
}

public struct UpstreamServer: Identifiable, Codable {
    public var id: String
    public var name: String
    public var ipAddress: String
    public var port: UInt16
    public var dohURL: String?
    public var isEnabled: Bool
    public var averageLatencyMs: Double
    public var failureCount: Int
    public var totalQueries: Int
    public var isHealthy: Bool
    
    public init(id: String = UUID().uuidString,
                name: String,
                ipAddress: String,
                port: UInt16 = 53,
                dohURL: String? = nil,
                isEnabled: Bool = true,
                averageLatencyMs: Double = 25.0,
                failureCount: Int = 0,
                totalQueries: Int = 0,
                isHealthy: Bool = true) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.port = port
        self.dohURL = dohURL
        self.isEnabled = isEnabled
        self.averageLatencyMs = averageLatencyMs
        self.failureCount = failureCount
        self.totalQueries = totalQueries
        self.isHealthy = isHealthy
    }
}

public final class DNSLoadBalancer {
    
    private let lock = NSLock()
    private var servers: [UpstreamServer]
    private var roundRobinIndex: Int = 0
    public var strategy: LoadBalancingStrategy = .racing
    
    public static let defaultServers: [UpstreamServer] = [
        UpstreamServer(name: "Cloudflare (Primary)", ipAddress: "1.1.1.1", port: 53, dohURL: "https://cloudflare-dns.com/dns-query", averageLatencyMs: 12.0),
        UpstreamServer(name: "Cloudflare (Secondary)", ipAddress: "1.0.0.1", port: 53, dohURL: "https://cloudflare-dns.com/dns-query", averageLatencyMs: 14.0),
        UpstreamServer(name: "Google (Primary)", ipAddress: "8.8.8.8", port: 53, dohURL: "https://dns.google/dns-query", averageLatencyMs: 18.0),
        UpstreamServer(name: "Google (Secondary)", ipAddress: "8.8.4.4", port: 53, dohURL: "https://dns.google/dns-query", averageLatencyMs: 20.0),
        UpstreamServer(name: "Quad9 (Malware Block)", ipAddress: "9.9.9.9", port: 53, dohURL: "https://dns.quad9.net/dns-query", averageLatencyMs: 24.0),
        UpstreamServer(name: "AdGuard (AdBlock)", ipAddress: "94.140.14.14", port: 53, dohURL: "https://dns.adguard.com/dns-query", averageLatencyMs: 28.0)
    ]
    
    public init(servers: [UpstreamServer] = DNSLoadBalancer.defaultServers) {
        self.servers = servers
    }
    
    // MARK: - Server Selection
    
    public func selectServersForQuery() -> [UpstreamServer] {
        lock.lock()
        defer { lock.unlock() }
        
        let activeServers = servers.filter { $0.isEnabled && $0.isHealthy }
        guard !activeServers.isEmpty else {
            // Fallback to any enabled server if all marked unhealthy
            return servers.filter { $0.isEnabled }
        }
        
        switch strategy {
        case .racing:
            // Pick top 2-3 lowest latency servers to race concurrently
            let sorted = activeServers.sorted { $0.averageLatencyMs < $1.averageLatencyMs }
            return Array(sorted.prefix(3))
            
        case .fastest:
            if let lowest = activeServers.min(by: { $0.averageLatencyMs < $1.averageLatencyMs }) {
                return [lowest]
            }
            return [activeServers[0]]
            
        case .weightedLatency:
            // Probabilistic selection inversely proportional to latency
            let totalInverseLatency = activeServers.reduce(0.0) { $0 + (1.0 / max(1.0, $1.averageLatencyMs)) }
            let random = Double.random(in: 0.0..<totalInverseLatency)
            var cumulative = 0.0
            for server in activeServers {
                cumulative += (1.0 / max(1.0, server.averageLatencyMs))
                if random <= cumulative {
                    return [server]
                }
            }
            return [activeServers[0]]
            
        case .roundRobin:
            let server = activeServers[roundRobinIndex % activeServers.count]
            roundRobinIndex = (roundRobinIndex + 1) % activeServers.count
            return [server]
        }
    }
    
    // MARK: - Feedback & Health Updating (EWMA)
    
    public func reportSuccess(serverIP: String, latencyMs: Double) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let index = servers.firstIndex(where: { $0.ipAddress == serverIP }) else { return }
        
        // EWMA update: 0.8 old + 0.2 new
        let alpha = 0.2
        servers[index].averageLatencyMs = (1.0 - alpha) * servers[index].averageLatencyMs + alpha * latencyMs
        servers[index].failureCount = 0
        servers[index].isHealthy = true
        servers[index].totalQueries += 1
    }
    
    public func reportFailure(serverIP: String) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let index = servers.firstIndex(where: { $0.ipAddress == serverIP }) else { return }
        servers[index].failureCount += 1
        
        // Circuit breaker: Trip after 3 consecutive failures
        if servers[index].failureCount >= 3 {
            servers[index].isHealthy = false
            servers[index].averageLatencyMs = min(2000.0, servers[index].averageLatencyMs * 1.5)
        }
    }
    
    public func getServersSnapshot() -> [UpstreamServer] {
        lock.lock()
        defer { lock.unlock() }
        return servers
    }
    
    public func updateServers(_ newServers: [UpstreamServer]) {
        lock.lock()
        defer { lock.unlock() }
        self.servers = newServers
    }
}
