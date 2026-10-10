//
//  DNSCache.swift
//  DNSGuardTunnel
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Ultra-low latency thread-safe LRU cache with TTL auto-decrement for DNS responses.
//

import Foundation

public final class DNSCache {
    
    public struct CacheEntry {
        public let key: String
        public let answers: [DNSResourceRecord]
        public let authorities: [DNSResourceRecord]
        public let additionals: [DNSResourceRecord]
        public let timestamp: Date
        public let initialTTL: UInt32
        
        public func remainingTTL(at date: Date = Date()) -> UInt32? {
            let elapsed = UInt32(max(0, date.timeIntervalSince(timestamp)))
            guard elapsed < initialTTL else { return nil }
            return initialTTL - elapsed
        }
    }
    
    public struct CacheStats {
        public var hits: Int = 0
        public var misses: Int = 0
        public var evictions: Int = 0
        public var count: Int = 0
    }
    
    private let capacity: Int
    private var storage: [String: CacheEntry] = [:]
    private var lruOrder: [String] = []
    private let lock = NSLock()
    
    public private(set) var stats = CacheStats()
    
    public init(capacity: Int = 4096) {
        self.capacity = capacity
    }
    
    private func cacheKey(name: String, type: DNSType) -> String {
        return "\(name.lowercased())#\(type.rawValue)"
    }
    
    // MARK: - Query Cache
    
    public func lookup(name: String, type: DNSType, queryID: UInt16) -> DNSPacket? {
        lock.lock()
        defer { lock.unlock() }
        
        let key = cacheKey(name: name, type: type)
        guard let entry = storage[key] else {
            stats.misses += 1
            return nil
        }
        
        let now = Date()
        guard let remaining = entry.remainingTTL(at: now) else {
            // Expired entry
            storage.removeValue(forKey: key)
            if let index = lruOrder.firstIndex(of: key) {
                lruOrder.remove(at: index)
            }
            stats.count = storage.count
            stats.misses += 1
            return nil
        }
        
        // Touch key for LRU
        if let idx = lruOrder.firstIndex(of: key) {
            lruOrder.remove(at: idx)
        }
        lruOrder.append(key)
        stats.hits += 1
        
        // Update TTLs in answer records
        let updatedAnswers = entry.answers.map { record -> DNSResourceRecord in
            var updated = record
            updated.ttl = remaining
            return updated
        }
        
        let header = DNSHeader(
            id: queryID,
            isResponse: true,
            opcode: 0,
            isAuthoritative: false,
            isTruncated: false,
            recursionDesired: true,
            recursionAvailable: true,
            responseCode: .noError,
            questionCount: 1,
            answerCount: UInt16(updatedAnswers.count),
            authorityCount: UInt16(entry.authorities.count),
            additionalCount: UInt16(entry.additionals.count)
        )
        
        let question = DNSQuestion(name: name, type: type)
        return DNSPacket(
            header: header,
            questions: [question],
            answers: updatedAnswers,
            authorities: entry.authorities,
            additionals: entry.additionals
        )
    }
    
    // MARK: - Insert Cache
    
    public func store(name: String, type: DNSType, packet: DNSPacket) {
        guard !packet.answers.isEmpty else { return }
        
        // Minimum TTL among answers
        let minTTL = packet.answers.map { $0.ttl }.min() ?? 60
        guard minTTL > 2 else { return } // Don't cache very short TTLs
        
        lock.lock()
        defer { lock.unlock() }
        
        let key = cacheKey(name: name, type: type)
        
        // Eviction if full
        if storage[key] == nil && storage.count >= capacity {
            if let oldest = lruOrder.first {
                lruOrder.removeFirst()
                storage.removeValue(forKey: oldest)
                stats.evictions += 1
            }
        }
        
        let entry = CacheEntry(
            key: key,
            answers: packet.answers,
            authorities: packet.authorities,
            additionals: packet.additionals,
            timestamp: Date(),
            initialTTL: minTTL
        )
        
        storage[key] = entry
        if let idx = lruOrder.firstIndex(of: key) {
            lruOrder.remove(at: idx)
        }
        lruOrder.append(key)
        stats.count = storage.count
    }
    
    public func purge() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
        lruOrder.removeAll()
        stats.count = 0
    }
}
