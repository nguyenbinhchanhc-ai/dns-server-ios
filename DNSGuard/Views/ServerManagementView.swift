//
//  ServerManagementView.swift
//  DNSGuard
//
//  Created for iOS Local DNS Optimizer.
//  Server Pool Manager with continuous real-time latency monitoring,
//  6 advanced load balancing algorithms, per-server load distribution,
//  Color Tagging, and QoS Server Priority Tiers (P0 - P3).
//

import SwiftUI

struct ServerManagementView: View {
    @ObservedObject var prober = ContinuousDNSProber.shared
    @ObservedObject var profileServer = ProfileServer.shared
    
    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newIP = ""
    @State private var newDoH = ""
    @State private var newTier: ServerPriorityTier = .p1
    
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
                            Text("Tỷ lệ phân phối tải & phân cấp QoS nhảy trực tiếp")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: 1. 6 LOAD BALANCING STRATEGIES SELECTION
                Section(
                    header: Text("6 Chiến lược cân bằng tải DNS nâng cao"),
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
                
                // MARK: 3. SERVER RANKING & COLOR-CODED LOAD SHARE
                // MARK: 3. SERVER RANKING & DYNAMIC HEALTH COLOR LOAD SHARE
                Section(
                    header: Text("Bảng máy chủ, Tình trạng phản hồi động & Chia tải"),
                    footer: Text("Màu sắc biến đổi realtime theo độ trễ. Tỷ lệ chia tải tự động điều phối theo thuật toán \(prober.activeMode.rawValue).")
                ) {
                    ForEach(prober.benchmarks.sorted(by: { $0.latencyMs < $1.latencyMs })) { server in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                // Server Brand Identification Badge
                                Text(server.brandBadge)
                                    .font(.system(size: 9, weight: .black))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.15))
                                    .foregroundColor(.primary)
                                    .cornerRadius(4)
                                
                                // Dynamic Real-Time Health Indicator
                                Circle()
                                    .fill(Color(hex: server.colorHex))
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: server.colorHex).opacity(0.5), lineWidth: 2)
                                            .scaleEffect(1.4)
                                    )
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(server.name)
                                            .fontWeight(.semibold)
                                        
                                        // Priority Badge (P0, P1, P2, P3)
                                        Text(server.priorityTier.badge)
                                            .font(.system(size: 9, weight: .black))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color(hex: server.priorityTier.colorHex).opacity(0.18))
                                            .foregroundColor(Color(hex: server.priorityTier.colorHex))
                                            .cornerRadius(4)
                                        
                                        if server.isFastest {
                                            Text("TOP 1")
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
                                        .foregroundColor(Color(hex: server.colorHex))
                                    
                                    Text(server.status)
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(Color(hex: server.colorHex))
                                    
                                    Text("Tải: \(String(format: "%.1f%%", server.loadPercentage))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: server.colorHex))
                                }
                            }
                            
                            // Visual Dynamic Health Color Load Distribution Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(hex: server.colorHex))
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
                
                // MARK: 4. DYNAMIC HEALTH SPECTRUM & BRAND LEGEND SECTION
                Section(
                    header: Text("Phổ màu phản hồi động Realtime & Nhận diện máy chủ"),
                    footer: Text("Màu sắc của máy chủ KHÔNG cố định mà tự động biến đổi liên tục theo mức phản hồi hiện tại (mỗi 2.2s). Thẻ chữ viết tắt (CF, GG, AG, Q9, ND) giúp bạn nhận diện riêng biệt từng máy chủ bất kể màu sắc đang biến đổi.")
                ) {
                    tierLegendRow(name: "Phản hồi < 15.0 ms", colorHex: "#34C759", tier: "EXC", desc: "Xanh Lục Emerald • Cực nhanh - Phản hồi ngay")
                    tierLegendRow(name: "Phản hồi 15.0 - 25.0 ms", colorHex: "#007AFF", tier: "GOOD", desc: "Xanh Lam Electric • Mượt mà - Nhanh")
                    tierLegendRow(name: "Phản hồi 25.0 - 40.0 ms", colorHex: "#FFD60A", tier: "NORM", desc: "Vàng Hổ Phách • Tiêu chuẩn - Ổn định")
                    tierLegendRow(name: "Phản hồi 40.0 - 75.0 ms", colorHex: "#FF9500", tier: "WARN", desc: "Cam Cảnh Báo • Trễ cao - Chậm")
                    tierLegendRow(name: "Phản hồi > 75.0 ms", colorHex: "#FF3B30", tier: "SLOW", desc: "Đỏ Cảnh Báo • Nghẽn mạng / Lag")
                    tierLegendRow(name: "Bộ Đệm RAM L1 Cache", colorHex: "#00C7BE", tier: "RAM", desc: "Xanh Mint Siêu Tốc • Truy xuất tức thì (<0.15ms)")
                }
                
                // MARK: 5. PROFILE GENERATOR
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
    
    private func tierLegendRow(name: String, colorHex: String, tier: String, desc: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 10, height: 10)
            
            Text(tier)
                .font(.system(size: 9, weight: .black))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color(hex: colorHex).opacity(0.18))
                .foregroundColor(Color(hex: colorHex))
                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
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
                    
                    Picker("Cấp độ ưu tiên QoS", selection: $newTier) {
                        ForEach(ServerPriorityTier.allCases) { tier in
                            Text(tier.rawValue).tag(tier)
                        }
                    }
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
                        latencyMs: 30.0,
                        colorHex: "#8E8E93",
                        priorityTier: newTier
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
}
