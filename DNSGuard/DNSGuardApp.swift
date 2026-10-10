//
//  DNSGuardApp.swift
//  DNSGuard
//
//  Created for iOS Local DNS Optimizer.
//  Main application lifecycle entry point initializing persistent storage,
//  RAM accelerator, continuous prober, and local profile server.
//

import SwiftUI

@main
struct DNSGuardApp: App {
    
    init() {
        // 1. Load persistent on-device data
        _ = StorageManager.shared
        
        // 2. Start local HTTP profile installer server
        _ = ProfileServer.shared
        
        // 3. Preload RAM cache L1 accelerator
        _ = RAMCacheAccelerator.shared
        
        // 4. Start continuous background DNS prober & smart query router
        _ = ContinuousDNSProber.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
