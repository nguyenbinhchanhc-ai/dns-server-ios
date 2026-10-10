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
                Section(
                    header: Text("Bảng máy chủ, Màu nhận diện & Cấp độ QoS (P0-P3)"),
                    footer: Text("Máy chủ P0 gánh vác các truy vấn khẩn cấp (Push/VoIP). Tỷ lệ chia tải tự động điều phối theo thuật toán \(prober.activeMode.rawValue).")
                ) {
                    ForEach(prober.benchmarks.sorted(by: { $0.latencyMs < $1.latencyMs })) { server in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color(hex: server.colorHex))
                                    .frame(width: 12, height: 12)
                                
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
                                        .foregroundColor(server.latencyMs < 18 ? .green : .orange)
                                    
                                    Text("Tải: \(String(format: "%.1f%%", server.loadPercentage))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: server.colorHex))
                                }
                            }
                            
                            // Visual Color Load Distribution Bar
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
                
                // MARK: 4. COLOR & PRIORITY TIER LEGEND SECTION
                Section(header: Text("Bảng phân loại màu sắc & Cấp độ QoS chuẩn")) {
                    tierLegendRow(name: "Cloudflare Primary (1.1.1.1)", colorHex: "#007AFF", tier: "P0", desc: "Xanh Lam • Tối Thượng (<15ms)")
                    tierLegendRow(name: "Cloudflare Secondary (1.0.0.1)", colorHex: "#32ADE6", tier: "P1", desc: "Xanh Cyan • Ưu Tiên Cao (15-25ms)")
                    tierLegendRow(name: "Google DNS Primary (8.8.8.8)", colorHex: "#34C759", tier: "P0", desc: "Xanh Lục • Tối Thượng Anycast (<15ms)")
                    tierLegendRow(name: "Google DNS Secondary (8.8.4.4)", colorHex: "#30B0C7", tier: "P1", desc: "Xanh Bạc Hà • Dự Phòng Nhanh (15-25ms)")
                    tierLegendRow(name: "AdGuard DNS (94.140.14.14)", colorHex: "#FF9500", tier: "P3", desc: "Cam Hổ Phách • Lọc Rác & Chặn Ad (0ms)")
                    tierLegendRow(name: "Quad9 Malware Filter (9.9.9.9)", colorHex: "#AF52DE", tier: "P2", desc: "Tím Thạch Anh • Tiêu Chuẩn (25-40ms)")
                    tierLegendRow(name: "NextDNS Zero-Trust (45.90.28.0)", colorHex: "#FF2D55", tier: "P2", desc: "Hồng Cánh Sen • Bảo Mật Chuyên Sâu (25-40ms)")
                    tierLegendRow(name: "Bộ Đệm RAM L1 Cache (Local)", colorHex: "#00C7BE", tier: "L1", desc: "Xanh Mint Siêu Tốc • Truy xuất tức thì (<0.15ms)")
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
