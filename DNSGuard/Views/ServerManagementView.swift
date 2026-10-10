//
//  ServerManagementView.swift
//  DNSGuard
//
//  Created for iOS Local DNS Optimizer.
//  Server Pool Manager with continuous real-time latency monitoring,
//  multi-mode load balancing control, and per-server load distribution.
//

import SwiftUI

struct ServerManagementView: View {
    @ObservedObject var prober = ContinuousDNSProber.shared
    @ObservedObject var profileServer = ProfileServer.shared
    
    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newIP = ""
    @State private var newDoH = ""
    
    var body: some View {
        NavigationView {
            List {
                // MARK: 0. REALTIME LIVE STREAM STATUS BAR
                Section {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.green.opacity(0.5), lineWidth: 2)
                                    .scaleEffect(1.4)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("REALTIME LIVE BALANCER")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.green)
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f QPS", prober.liveQPS))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                            Text("Tỷ lệ phân phối tải đang nhảy trực tiếp theo độ trễ")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: 1. LOAD BALANCING STRATEGY SELECTION
                Section(
                    header: Text("Chiến lược cân bằng tải DNS"),
                    footer: Text(prober.activeMode.description)
                ) {
                    Picker("Chế độ", selection: $prober.activeMode) {
                        ForEach(DNSLoadBalancingMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(InlinePickerStyle())
                }
                
                // MARK: 2. LIVE MONITOR STATUS
                Section(header: Text("Tình trạng đo liên tục (Live Monitor)")) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(prober.isProbingActive ? Color.green : Color.gray)
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(prober.isProbingActive ? "Đang liên tục kiểm tra (Mỗi 2.2s)" : "Đang tạm dừng")
                                    .fontWeight(.semibold)
                                Text("Lần đo: \(prober.totalProbesCompleted) • Nhanh nhất: \(prober.fastestServerName)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            prober.probeAllServersOnce()
                        }) {
                            Text("Đo lại ngay")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: 3. SERVER RANKING & LOAD SHARE
                Section(
                    header: Text("Bảng máy chủ & Tỷ lệ chia tải (%)"),
                    footer: Text("Tỷ lệ phân phối tải được tính toán tự động dựa trên thuật toán \(prober.activeMode.rawValue).")
                ) {
                    ForEach(prober.benchmarks.sorted(by: { $0.latencyMs < $1.latencyMs })) { server in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(latencyColor(server.latencyMs))
                                    .frame(width: 10, height: 10)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(server.name)
                                            .fontWeight(.semibold)
                                        if server.isFastest {
                                            Text("FASTEST")
                                                .font(.system(size: 9, weight: .bold))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.15))
                                                .foregroundColor(.green)
                                                .cornerRadius(4)
                                        }
                                    }
                                    Text("\(server.ip) • Ổn định \(server.stabilityScore)%")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(String(format: "%.1f ms", server.latencyMs))
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(latencyColor(server.latencyMs))
                                    
                                    Text("Tải: \(String(format: "%.1f%%", server.loadPercentage))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // Visual Load Distribution Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(server.isFastest ? Color.green : Color.blue)
                                        .frame(width: max(4, geo.size.width * CGFloat(server.loadPercentage / 100.0)), height: 6)
                                }
                            }
                            .frame(height: 6)
                            
                            HStack {
                                Text("Đã xử lý: \(server.queryCount) truy vấn")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Thành công: \(String(format: "%.1f%%", server.successRate))")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // MARK: 4. PROFILE GENERATOR
                Section(header: Text("Tải Profile Riêng Theo Từng Máy Chủ")) {
                    Button(action: {
                        profileServer.openProfileInSafari()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Cài Profile tổ hợp tối ưu (Cloudflare + Google DoH)")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Máy chủ & Chia tải")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                addServerSheet
            }
        }
    }
    
    private var addServerSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin máy chủ mới")) {
                    TextField("Tên máy chủ (vd: OpenDNS, NextDNS)", text: $newName)
                    TextField("Địa chỉ IPv4", text: $newIP)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("URL DoH (Tùy chọn)", text: $newDoH)
                        .keyboardType(.URL)
                }
            }
            .navigationTitle("Thêm máy chủ DNS")
            .navigationBarItems(
                leading: Button("Hủy") { showingAddSheet = false },
                trailing: Button("Thêm") {
                    guard !newName.isEmpty, !newIP.isEmpty else { return }
                    let newBenchmark = LiveServerBenchmark(
                        name: newName,
                        ip: newIP,
                        dohURL: newDoH.isEmpty ? "https://dns.google/dns-query" : newDoH,
                        latencyMs: 30.0
                    )
                    prober.benchmarks.append(newBenchmark)
                    newName = ""
                    newIP = ""
                    newDoH = ""
                    showingAddSheet = false
                }
                .disabled(newName.isEmpty || newIP.isEmpty)
            )
        }
    }
    
    private func latencyColor(_ ms: Double) -> Color {
        if ms < 18 { return .green }
        if ms < 35 { return .orange }
        return .red
    }
}
