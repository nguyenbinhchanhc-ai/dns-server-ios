//
//  VPNManager.swift
//  DNSGuard
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Manages NETunnelProviderManager configuration and VPN connection lifecycle.
//

import NetworkExtension
import Combine

public enum VPNConnectionStatus: String {
    case disconnected = "Disconnected"
    case connecting = "Connecting..."
    case connected = "Active & Protecting"
    case disconnecting = "Disconnecting..."
    case reasserting = "Reconnecting..."
    case invalid = "Invalid Configuration"
}

public final class VPNManager: ObservableObject {
    
    public static let shared = VPNManager()
    
    @Published public var status: VPNConnectionStatus = .disconnected
    @Published public var isEnabled: Bool = false
    @Published public var connectedDuration: TimeInterval = 0
    @Published public var errorMessage: String?
    
    private var providerManager: NETunnelProviderManager?
    private var durationTimer: Timer?
    private var connectDate: Date?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupStatusObserver()
        loadOrCreateTunnelManager()
    }
    
    // MARK: - Manager Configuration
    
    public func loadOrCreateTunnelManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load VPN preferences: \(error.localizedDescription)"
                }
                return
            }
            
            if let existingManager = managers?.first {
                self.providerManager = existingManager
                self.updateStatusFromManager(existingManager)
            } else {
                self.createNewTunnelManager()
            }
        }
    }
    
    private func createNewTunnelManager() {
        let manager = NETunnelProviderManager()
        let config = NETunnelProviderProtocol()
        let baseBundle = Bundle.main.bundleIdentifier ?? "com.antigravity.dnsguard"
        config.providerBundleIdentifier = "\(baseBundle).tunnel"
        config.serverAddress = "DNSGuard Local Engine"
        
        manager.protocolConfiguration = config
        manager.localizedDescription = "DNSGuard Smart VPN"
        manager.isEnabled = true
        
        manager.saveToPreferences { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Lỗi lưu VPN: \(error.localizedDescription)"
                }
            } else {
                self.providerManager = manager
                manager.loadFromPreferences { _ in
                    self.updateStatusFromManager(manager)
                }
            }
        }
    }
    
    // MARK: - Toggle VPN
    
    public func toggleVPN() {
        if status == .connected {
            stopVPN()
        } else if status == .disconnected {
            startVPN()
        }
    }
    
    public func startVPN() {
        guard let manager = providerManager else {
            loadOrCreateTunnelManager()
            return
        }
        
        let baseBundle = Bundle.main.bundleIdentifier ?? "com.antigravity.dnsguard"
        if let config = manager.protocolConfiguration as? NETunnelProviderProtocol {
            config.providerBundleIdentifier = "\(baseBundle).tunnel"
            manager.protocolConfiguration = config
        }
        
        manager.isEnabled = true
        manager.saveToPreferences { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Không thể thêm cấu hình VPN: \(error.localizedDescription)"
                }
                return
            }
            
            manager.loadFromPreferences { [weak self] loadError in
                guard let self = self else { return }
                if let loadError = loadError {
                    DispatchQueue.main.async {
                        self.errorMessage = "Lỗi tải cấu hình VPN: \(loadError.localizedDescription)"
                    }
                    return
                }
                do {
                    try manager.connection.startVPNTunnel(options: nil)
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Không thể khởi động VPN: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    public func stopVPN() {
        providerManager?.connection.stopVPNTunnel()
    }
    
    // MARK: - Status Tracking
    
    private func setupStatusObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange(_:)),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }
    
    @objc private func vpnStatusDidChange(_ notification: Notification) {
        guard let connection = notification.object as? NEVPNConnection else { return }
        updateStatus(connection.status)
    }
    
    private func updateStatusFromManager(_ manager: NETunnelProviderManager) {
        updateStatus(manager.connection.status)
    }
    
    private func updateStatus(_ neStatus: NEVPNStatus) {
        DispatchQueue.main.async {
            switch neStatus {
            case .invalid:
                self.status = .invalid
                self.isEnabled = false
                self.stopDurationTimer()
            case .disconnected:
                self.status = .disconnected
                self.isEnabled = false
                self.stopDurationTimer()
            case .connecting:
                self.status = .connecting
                self.isEnabled = false
            case .connected:
                self.status = .connected
                self.isEnabled = true
                self.startDurationTimer()
            case .reasserting:
                self.status = .reasserting
                self.isEnabled = true
            case .disconnecting:
                self.status = .disconnecting
                self.isEnabled = false
                self.stopDurationTimer()
            @unknown default:
                self.status = .disconnected
                self.isEnabled = false
                self.stopDurationTimer()
            }
        }
    }
    
    private func startDurationTimer() {
        if connectDate == nil {
            connectDate = Date()
        }
        durationTimer?.invalidate()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.connectDate else { return }
            self.connectedDuration = Date().timeIntervalSince(start)
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
        connectDate = nil
        connectedDuration = 0
    }
}
