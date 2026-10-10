//
//  DashboardView.swift
//  DNSGuard
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Main Dashboard: VPN activation toggle, speed acceleration metrics,
//  and packet error self-healing status.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var vpnManager = VPNManager.shared
    @ObservedObject var dataManager = SharedDataManager.shared
    
    @State private var isPulsing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Top VPN Status & Shield
                    vpnStatusCard
                    
                    // Core Telemetry & Acceleration Metrics
                    metricsGrid
                    
                    // Self-Healing & Error Correction Showcase
                    selfHealingBanner
                    
                    // Upstream Active Routing Info
                    routingOverviewCard
                }
                .padding()
            }
            .navigationTitle("DNSGuard Optimizer")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .alert("Cấp quyền VPN iOS", isPresented: Binding(
                get: { vpnManager.errorMessage != nil },
                set: { if !$0 { vpnManager.errorMessage = nil } }
            )) {
                Button("Đã hiểu", role: .cancel) {
                    vpnManager.errorMessage = nil
                }
            } message: {
                Text(vpnManager.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - VPN Status Card
    
    private var vpnStatusCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isPulsing && vpnManager.status == .connected ? 1.15 : 1.0)
                    .animation(isPulsing && vpnManager.status == .connected ? Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default, value: isPulsing)
                
                Circle()
                    .fill(statusColor.opacity(0.25))
                    .frame(width: 110, height: 110)
                
                Button(action: {
                    withAnimation {
                        vpnManager.toggleVPN()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 80, height: 80)
                            .shadow(color: statusColor.opacity(0.4), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: vpnManager.status == .connected ? "lock.shield.fill" : "power")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                isPulsing = true
            }
            
            VStack(spacing: 4) {
                Text(vpnManager.status.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
                
                if vpnManager.status == .connected {
                    Text(formatDuration(vpnManager.connectedDuration))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Chạm để kích hoạt VPN ảo bảo vệ & tăng tốc DNS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Metrics Grid
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            metricCard(
                title: "Tổng truy vấn",
                value: "\(dataManager.totalQueries)",
                subtitle: "Đã qua tunnel ảo",
                icon: "arrow.triangle.swap",
                color: .blue
            )
            
            metricCard(
                title: "Tăng tốc Cache",
                value: String(format: "%.1f%%", dataManager.cacheHitRate),
                subtitle: "\(dataManager.cacheHits) hits (< 0.5ms)",
                icon: "bolt.fill",
                color: .orange
            )
            
            metricCard(
                title: "Tự sửa gói lỗi",
                value: "\(dataManager.totalRepairs)",
                subtitle: "\(dataManager.repairedChecksums) CS / \(dataManager.healedTruncations) TC",
                icon: "wrench.and.screwdriver.fill",
                color: .green
            )
            
            metricCard(
                title: "Độ trễ trung bình",
                value: String(format: "%.1f ms", dataManager.averageLatency),
                subtitle: "Đua máy chủ tối ưu",
                icon: "speedometer",
                color: .purple
            )
        }
    }
    
    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Self-Healing Banner
    
    private var selfHealingBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 22))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Cơ chế tự sửa lỗi tự động (Active)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Tự động vá lỗi Checksum IP/UDP, phục hồi gói tin bị cắt cụt (TC Truncated) và chống suy hao.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Routing Overview
    
    private var routingOverviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Chiến lược cân bằng tải", systemImage: "slider.horizontal.3")
                    .font(.subheadline.bold())
                Spacer()
                Text(dataManager.currentStrategy.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Giao thức")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("UDP + DoH Racing")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading) {
                    Text("Mạng ảo TUN")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("10.8.0.1:53 (Loopback)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading) {
                    Text("Bảo vệ DNS")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("100% Hệ thống iOS")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
    
    private var statusColor: Color {
        switch vpnManager.status {
        case .connected: return .green
        case .connecting, .reasserting: return .orange
        case .disconnected, .invalid, .disconnecting: return .gray
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
