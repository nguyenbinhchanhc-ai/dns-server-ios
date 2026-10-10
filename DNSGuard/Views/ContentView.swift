//
//  ContentView.swift
//  DNSGuard
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Main application tab container.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Tổng quan", systemImage: "shield.lefthalf.filled")
                }
                .tag(0)
            
            ServerManagementView()
                .tabItem {
                    Label("Máy chủ DNS", systemImage: "server.rack")
                }
                .tag(1)
            
            LogsView()
                .tabItem {
                    Label("Nhật ký", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Cài đặt", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}
