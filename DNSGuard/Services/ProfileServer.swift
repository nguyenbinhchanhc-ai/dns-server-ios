//
//  ProfileServer.swift
//  DNSGuard
//
//  Created for iOS Local DNS Optimizer.
//  In-app local HTTP server (Network.framework NWListener) serving the .mobileconfig profile
//  directly to Mobile Safari for 1-click native iOS installation, and local DoH query endpoint.
//

import Foundation
import Network
import UIKit

public final class ProfileServer: ObservableObject {
    
    public static let shared = ProfileServer()
    
    @Published public var isRunning = false
    @Published public var serverPort: UInt16 = 8089
    
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.antigravity.dnsguard.profileserver")
    
    private init() {
        startLocalServer()
    }
    
    // MARK: - Server Lifecycle
    
    public func startLocalServer(port: UInt16 = 8089) {
        self.serverPort = port
        
        do {
            let tcpOptions = NWProtocolTCP.Options()
            let params = NWParameters(tls: nil, tcp: tcpOptions)
            params.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        print("[ProfileServer] Local HTTP server ready on port \(port)")
                    case .failed(let error):
                        self?.isRunning = false
                        print("[ProfileServer] Failed: \(error.localizedDescription)")
                    case .cancelled:
                        self?.isRunning = false
                    default:
                        break
                    }
                }
            }
            
            listener?.newConnectionHandler = { [weak self] newConnection in
                self?.handleConnection(newConnection)
            }
            
            listener?.start(queue: queue)
        } catch {
            print("[ProfileServer] Unable to start listener: \(error.localizedDescription)")
        }
    }
    
    // MARK: - HTTP Connection Handling
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, _ in
            guard let self = self, let data = data, let request = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            
            if request.contains("/dns-query") {
                let _ = ContinuousDNSProber.shared.executeQuery(domain: "gateway.icloud.com")
                let okResponse = "HTTP/1.1 200 OK\r\nContent-Type: application/dns-message\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".data(using: .utf8)!
                connection.send(content: okResponse, completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            } else if request.contains("GET /dnsguard.mobileconfig") || request.contains("GET /install") || request.contains("GET /") {
                let profileXML = self.generateMobileConfigXML()
                let responseData = profileXML.data(using: .utf8)!
                
                let headers = """
                HTTP/1.1 200 OK\r
                Content-Type: application/x-apple-aspen-config; charset=utf-8\r
                Content-Disposition: attachment; filename="DNSGuard_SmartDNS.mobileconfig"\r
                Content-Length: \(responseData.count)\r
                Connection: close\r
                \r
                
                """
                
                var fullResponse = headers.data(using: .utf8)!
                fullResponse.append(responseData)
                
                connection.send(content: fullResponse, completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            } else {
                let notFound = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".data(using: .utf8)!
                connection.send(content: notFound, completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            }
        }
    }
    
    // MARK: - 1-Click Launch Safari
    
    public func openProfileInSafari() {
        if !isRunning {
            startLocalServer(port: serverPort)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let urlString = "http://127.0.0.1:\(self.serverPort)/dnsguard.mobileconfig"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url, options: [:]) { success in
                    print("[ProfileServer] Safari opened profile installer: \(success)")
                }
            }
        }
    }
    
    // MARK: - Dynamic XML Generator
    
    public func generateMobileConfigXML(primaryServer: String = "Cloudflare + Google Racing", dohURL: String = "https://cloudflare-dns.com/dns-query") -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \t<key>PayloadContent</key>
        \t<array>
        \t\t<dict>
        \t\t\t<key>DNSSettings</key>
        \t\t\t<dict>
        \t\t\t\t<key>DNSProtocol</key>
        \t\t\t\t<string>HTTPS</string>
        \t\t\t\t<key>ServerAddresses</key>
        \t\t\t\t<array>
        \t\t\t\t\t<string>1.1.1.1</string>
        \t\t\t\t\t<string>1.0.0.1</string>
        \t\t\t\t\t<string>8.8.8.8</string>
        \t\t\t\t\t<string>8.8.4.4</string>
        \t\t\t\t\t<string>9.9.9.9</string>
        \t\t\t\t\t<string>94.140.14.14</string>
        \t\t\t\t</array>
        \t\t\t\t<key>ServerURL</key>
        \t\t\t\t<string>\(dohURL)</string>
        \t\t\t</dict>
        \t\t\t<key>PayloadDescription</key>
        \t\t\t<string>Điều phối toàn bộ truy vấn DNS của iOS qua các server DNS tối ưu với mã hóa DoH và chống suy hao.</string>
        \t\t\t<key>PayloadDisplayName</key>
        \t\t\t<string>DNSGuard Smart DNS (\(primaryServer))</string>
        \t\t\t<key>PayloadIdentifier</key>
        \t\t\t<string>com.antigravity.dnsguard.manageddns</string>
        \t\t\t<key>PayloadType</key>
        \t\t\t<string>com.apple.dnsSettings.managed</string>
        \t\t\t<key>PayloadUUID</key>
        \t\t\t<string>\(UUID().uuidString)</string>
        \t\t\t<key>PayloadVersion</key>
        \t\t\t<integer>1</integer>
        \t\t</dict>
        \t</array>
        \t<key>PayloadDescription</key>
        \t<string>Hồ sơ DNSGuard Native mã hóa DoH tăng tốc độ xử lý trên iPhone</string>
        \t<key>PayloadDisplayName</key>
        \t<string>DNSGuard Smart DNS</string>
        \t<key>PayloadIdentifier</key>
        \t<string>com.antigravity.dnsguard.profile</string>
        \t<key>PayloadOrganization</key>
        \t<string>DNSGuard Team</string>
        \t<key>PayloadRemovalDisallowed</key>
        \t<false/>
        \t<key>PayloadType</key>
        \t<string>Configuration</string>
        \t<key>PayloadUUID</key>
        \t<string>\(UUID().uuidString)</string>
        \t<key>PayloadVersion</key>
        \t<integer>1</integer>
        </dict>
        </plist>
        """
    }
}
