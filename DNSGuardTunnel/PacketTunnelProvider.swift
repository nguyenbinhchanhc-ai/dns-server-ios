//
//  PacketTunnelProvider.swift
//  DNSGuardTunnel
//
//  Created for iOS Local DNS VPN & Optimizer.
//  NetworkExtension tunnel provider intercepting system-wide DNS traffic on TUN loopback.
//

import NetworkExtension
import Foundation

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var isRunning = false
    private let engine = DNSEngine.shared
    private var statsSyncTimer: Timer?
    
    // MARK: - Tunnel Lifecycle
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        NSLog("[DNSGuardTunnel] Starting Local DNS VPN tunnel...")
        
        let tunnelSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.8.0.1")
        
        // Configure Virtual Interface IPv4
        let ipv4Settings = NEIPv4Settings(addresses: ["10.8.0.2"], subnetMasks: ["255.255.255.0"])
        // Only route the virtual DNS gateway through the tunnel (Split Tunneling)
        ipv4Settings.includedRoutes = [NEIPv4Route(destinationAddress: "10.8.0.1", subnetMask: "255.255.255.255")]
        tunnelSettings.ipv4Settings = ipv4Settings
        
        // Intercept all DNS traffic through virtual gateway
        let dnsSettings = NEDNSSettings(servers: ["10.8.0.1"])
        dnsSettings.matchDomains = [""] // Catch-all wildcard
        tunnelSettings.dnsSettings = dnsSettings
        
        // Load User Config from Shared Defaults
        loadUserConfigurations()
        
        setTunnelNetworkSettings(tunnelSettings) { [weak self] error in
            if let error = error {
                NSLog("[DNSGuardTunnel] Failed to set network settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            
            self?.isRunning = true
            self?.startPacketReadingLoop()
            self?.startStatsSync()
            NSLog("[DNSGuardTunnel] Tunnel established successfully. Packet reader listening on TUN.")
            completionHandler(nil)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("[DNSGuardTunnel] Stopping tunnel with reason: \(reason.rawValue)")
        isRunning = false
        statsSyncTimer?.invalidate()
        statsSyncTimer = nil
        completionHandler()
    }
    
    // MARK: - Low-Level TUN Packet Processing
    
    private func startPacketReadingLoop() {
        guard isRunning else { return }
        
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self, self.isRunning else { return }
            
            for (index, packet) in packets.enumerated() {
                let packetProtocol = protocols[index]
                
                // Process IPv4 packets (AF_INET = 2)
                if packetProtocol.intValue == AF_INET {
                    self.engine.handleIncomingIPPacket(packet) { replyData in
                        guard let replyData = replyData else { return }
                        self.packetFlow.writePackets([replyData], withProtocols: [NSNumber(value: AF_INET)])
                    }
                }
            }
            
            // Loop reader asynchronously
            self.startPacketReadingLoop()
        }
    }
    
    // MARK: - App Group Telemetry Synchronization
    
    private func loadUserConfigurations() {
        if let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.appGroupId) {
            if let rawStrategy = sharedDefaults.string(forKey: AppGroupConstants.keyLoadBalancingStrategy),
               let strategy = LoadBalancingStrategy(rawValue: rawStrategy) {
                engine.loadBalancer.strategy = strategy
            }
        }
    }
    
    private func startStatsSync() {
        DispatchQueue.main.async { [weak self] in
            self?.statsSyncTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self?.syncTelemetryToSharedDefaults()
            }
        }
    }
    
    private func syncTelemetryToSharedDefaults() {
        guard let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.appGroupId) else { return }
        
        let engineTelemetry = engine.telemetry
        let repairStats = PacketRepairer.sharedTelemetry
        
        sharedDefaults.set(engineTelemetry.totalQueriesIntercepted, forKey: AppGroupConstants.keyTotalQueries)
        sharedDefaults.set(engineTelemetry.cacheHits, forKey: AppGroupConstants.keyCacheHits)
        sharedDefaults.set(repairStats.repairedIPChecksums + repairStats.repairedUDPChecksums, forKey: AppGroupConstants.keyRepairedChecksums)
        sharedDefaults.set(repairStats.truncatedPacketsHealed, forKey: AppGroupConstants.keyHealedTruncations)
        sharedDefaults.set(engineTelemetry.activeLatencyMs, forKey: AppGroupConstants.keyAverageLatency)
    }
}
