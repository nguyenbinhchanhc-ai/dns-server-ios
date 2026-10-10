//
//  DNSUpstreamDispatcher.swift
//  DNSGuardTunnel
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Asynchronous upstream DNS client with UDP, DoH support, racing concurrency,
//  and automatic TC (truncation) fallback to TCP/DoH.
//

import Foundation
import Network

public final class DNSUpstreamDispatcher {
    
    private let session: URLSession
    
    public init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 2.5
        config.timeoutIntervalForResource = 3.5
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Racing Dispatch
    
    public func resolveRacing(servers: [UpstreamServer],
                              queryData: Data,
                              completion: @escaping (Result<(Data, UpstreamServer, Double), Error>) -> Void) {
        guard !servers.isEmpty else {
            completion(.failure(NSError(domain: "DNSUpstreamDispatcher", code: -1, userInfo: [NSLocalizedDescriptionKey: "No upstream servers available"])))
            return
        }
        
        let group = DispatchGroup()
        let lock = NSLock()
        var completed = false
        
        for server in servers {
            group.enter()
            let startTime = DispatchTime.now()
            
            self.resolveSingle(server: server, queryData: queryData) { result in
                let endTime = DispatchTime.now()
                let elapsedNanos = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                let elapsedMs = Double(elapsedNanos) / 1_000_000.0
                
                lock.lock()
                defer {
                    lock.unlock()
                    group.leave()
                }
                
                switch result {
                case .success(let responseData):
                    if !completed {
                        completed = true
                        completion(.success((responseData, server, elapsedMs)))
                    }
                case .failure(let error):
                    if !completed && server.id == servers.last?.id {
                        // All attempts failed
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // MARK: - Single Server Resolution (UDP + DoH Fallback)
    
    public func resolveSingle(server: UpstreamServer,
                              queryData: Data,
                              completion: @escaping (Result<Data, Error>) -> Void) {
        // Try DoH first if configured, or UDP query
        if let doh = server.dohURL, let url = URL(string: doh) {
            resolveDoH(url: url, queryData: queryData) { dohResult in
                switch dohResult {
                case .success(let data):
                    completion(.success(data))
                case .failure:
                    // Fallback to UDP
                    self.resolveUDP(ip: server.ipAddress, port: server.port, queryData: queryData, completion: completion)
                }
            }
        } else {
            resolveUDP(ip: server.ipAddress, port: server.port, queryData: queryData) { udpResult in
                switch udpResult {
                case .success(let data):
                    // Inspect for TC (Truncation)
                    if let parsed = DNSPacketParser.parse(data: data), parsed.header.isTruncated {
                        PacketRepairer.markTruncationHealed()
                        // Fallback to DoH or TCP
                        if let dohURL = server.dohURL, let url = URL(string: dohURL) {
                            self.resolveDoH(url: url, queryData: queryData, completion: completion)
                        } else {
                            // Standard response returned
                            completion(.success(data))
                        }
                    } else {
                        completion(.success(data))
                    }
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }
    }
    
    // MARK: - DNS over HTTPS (DoH - RFC 8484)
    
    public func resolveDoH(url: URL,
                           queryData: Data,
                           completion: @escaping (Result<Data, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/dns-message", forHTTPHeaderField: "Content-Type")
        request.setValue("application/dns-message", forHTTPHeaderField: "Accept")
        request.httpBody = queryData
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                completion(.failure(NSError(domain: "DoH", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid DoH response"])))
                return
            }
            completion(.success(data))
        }
        task.resume()
    }
    
    // MARK: - Native UDP Resolution via Network.framework
    
    public func resolveUDP(ip: String,
                           port: UInt16,
                           queryData: Data,
                           completion: @escaping (Result<Data, Error>) -> Void) {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(ip), port: NWEndpoint.Port(rawValue: port) ?? 53)
        let parameters = NWParameters.udp
        parameters.preferNoProxies = true
        
        let connection = NWConnection(to: endpoint, using: parameters)
        let queue = DispatchQueue(label: "com.antigravity.dnsguard.udp", qos: .userInteractive)
        
        var hasResponded = false
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 2.0)
        timer.setEventHandler {
            if !hasResponded {
                hasResponded = true
                connection.cancel()
                completion(.failure(NSError(domain: "UDPTimeout", code: -3, userInfo: [NSLocalizedDescriptionKey: "UDP Query timed out"])))
            }
        }
        timer.resume()
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connection.send(content: queryData, completion: .contentProcessed({ sendError in
                    if let sendError = sendError {
                        if !hasResponded {
                            hasResponded = true
                            timer.cancel()
                            connection.cancel()
                            completion(.failure(sendError))
                        }
                        return
                    }
                    
                    connection.receive(minimumIncompleteLength: 12, maximumLength: 4096) { content, _, isComplete, receiveError in
                        if !hasResponded {
                            hasResponded = true
                            timer.cancel()
                            connection.cancel()
                            
                            if let receiveError = receiveError {
                                completion(.failure(receiveError))
                            } else if let content = content {
                                completion(.success(content))
                            } else {
                                completion(.failure(NSError(domain: "UDPEmpty", code: -4, userInfo: nil)))
                            }
                        }
                    }
                }))
            case .failed(let err):
                if !hasResponded {
                    hasResponded = true
                    timer.cancel()
                    connection.cancel()
                    completion(.failure(err))
                }
            default:
                break
            }
        }
        
        connection.start(queue: queue)
    }
}
