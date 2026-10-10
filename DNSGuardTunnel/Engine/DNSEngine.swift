//
//  DNSEngine.swift
//  DNSGuardTunnel
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Core Orchestrator coordinating packet ingestion, cache inspection,
//  multi-server load balancing, packet repair, and telemetry.
//

import Foundation

public final class DNSEngine {
    
    public static let shared = DNSEngine()
    
    public let cache: DNSCache
    public let loadBalancer: DNSLoadBalancer
    public let dispatcher: DNSUpstreamDispatcher
    
    public struct EngineTelemetry {
        public var totalQueriesIntercepted: Int = 0
        public var cacheHits: Int = 0
        public var upstreamQueries: Int = 0
        public var activeLatencyMs: Double = 0.0
    }
    
    public private(set) var telemetry = EngineTelemetry()
    private let lock = NSLock()
    
    public init(cacheCapacity: Int = 4096) {
        self.cache = DNSCache(capacity: cacheCapacity)
        self.loadBalancer = DNSLoadBalancer()
        self.dispatcher = DNSUpstreamDispatcher()
    }
    
    // MARK: - Ingestion & Pipeline
    
    public func handleIncomingIPPacket(_ packetData: Data, completion: @escaping (Data?) -> Void) {
        var mutablePacket = packetData
        
        // Step 1: Self-heal IPv4 Checksum if damaged
        _ = PacketRepairer.verifyAndRepairIPChecksum(packetData: &mutablePacket)
        
        // Step 2: Parse raw IP/UDP layers
        guard let parsed = ParsedPacket(data: mutablePacket) else {
            PacketRepairer.markMalformedPacketFiltered()
            completion(nil)
            return
        }
        
        // Verify destination port is 53 (DNS)
        guard parsed.udpHeader.destinationPort == 53 else {
            completion(nil)
            return
        }
        
        lock.lock()
        telemetry.totalQueriesIntercepted += 1
        lock.unlock()
        
        // Step 3: Parse DNS Wire-Format
        guard let dnsPacket = DNSPacketParser.parse(data: parsed.payload),
              let firstQuestion = dnsPacket.questions.first else {
            PacketRepairer.markMalformedPacketFiltered()
            completion(nil)
            return
        }
        
        // Step 4: Ultra-Fast Cache Lookup
        if let cachedResponse = cache.lookup(name: firstQuestion.name, type: firstQuestion.type, queryID: dnsPacket.header.id) {
            let serializedDNS = DNSPacketParser.serialize(packet: cachedResponse)
            
            // Craft raw IP+UDP packet swapping src/dst
            let replyPacket = PacketRepairer.craftRawIPUDPPacket(
                sourceIP: parsed.ipHeader.destinationAddress,
                destinationIP: parsed.ipHeader.sourceAddress,
                sourcePort: parsed.udpHeader.destinationPort,
                destinationPort: parsed.udpHeader.sourcePort,
                dnsPayload: serializedDNS
            )
            
            lock.lock()
            telemetry.cacheHits += 1
            lock.unlock()
            
            completion(replyPacket)
            return
        }
        
        // Step 5: Load Balancing & Racing Upstream Dispatch
        let candidateServers = loadBalancer.selectServersForQuery()
        
        dispatcher.resolveRacing(servers: candidateServers, queryData: parsed.payload) { [weak self] result in
            guard let self = self else {
                completion(nil)
                return
            }
            
            switch result {
            case .success(let (responseData, chosenServer, latencyMs)):
                // Update Load Balancer health & moving latency
                self.loadBalancer.reportSuccess(serverIP: chosenServer.ipAddress, latencyMs: latencyMs)
                
                self.lock.lock()
                self.telemetry.upstreamQueries += 1
                self.telemetry.activeLatencyMs = latencyMs
                self.lock.unlock()
                
                // Parse response to store in cache & verify integrity
                if let parsedResponse = DNSPacketParser.parse(data: responseData) {
                    self.cache.store(name: firstQuestion.name, type: firstQuestion.type, packet: parsedResponse)
                }
                
                // Step 6: Craft clean wire-format response with valid checksums
                let replyPacket = PacketRepairer.craftRawIPUDPPacket(
                    sourceIP: parsed.ipHeader.destinationAddress,
                    destinationIP: parsed.ipHeader.sourceAddress,
                    sourcePort: parsed.udpHeader.destinationPort,
                    destinationPort: parsed.udpHeader.sourcePort,
                    dnsPayload: responseData
                )
                
                completion(replyPacket)
                
            case .failure(let error):
                NSLog("[DNSEngine] Resolution error: \(error.localizedDescription)")
                for server in candidateServers {
                    self.loadBalancer.reportFailure(serverIP: server.ipAddress)
                }
                completion(nil)
            }
        }
    }
}
