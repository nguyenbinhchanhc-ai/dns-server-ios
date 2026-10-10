//
//  DNSGuardApp.swift
//  DNSGuard
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Main application lifecycle entry point.
//

import SwiftUI

@main
struct DNSGuardApp: App {
    
    init() {
        // Initialize VPN Manager preferences on startup
        VPNManager.shared.loadOrCreateTunnelManager()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
