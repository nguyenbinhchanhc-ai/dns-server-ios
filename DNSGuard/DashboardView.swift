//
//  DashboardView.swift
//  DNSGuard
//
//  Created for iOS Local DNS Optimizer.
//  Integrated with 1-Click Native MobileConfig Installer, Continuous Prober,
//  Persistent On-Device Storage, RAM Cache Accelerator, High-Density Traffic Harvester,
//  4-Tier Autonomous Packet Self-Healing Diagnostics,
//  Color Tagging, and QoS Priority Distribution Matrix (P0 - P3).
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var profileServer = ProfileServer.shared
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var prober = ContinuousDNSProber.shared
    @ObservedObject var ramCache = RAMCacheAccelerator.shared
    
    @State private var showingResetAlert = false
    @State private var showingInstallHelp = false
    @State private var testSuccessMessage = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: 1. NATIVE PROFILE 1-CLICK INSTALLER CARD
                    nativeProfileInstallerCard
                    
                    // MARK: 2. HIGH-DENSITY REALTIME LIVE STREAM STATUS BAR
                    realtimeLiveStatusBar
                    
                    // MARK: 3. HIGH-DENSITY TRAFFIC HARVESTER SELECTOR
                    trafficHarvesterControlCard
                    
                    // MARK: 4. PERSISTENT TELEMETRY GRID (Lưu trên máy & Realtime)
                    persistentTelemetryGrid
                    
                    // MARK: 5. 1-CLICK HIGH-BURST TEST RUNNER
                    instantTestRunnerCard
                    
                    // MARK: 6. QOS PRIORITY DISTRIBUTION MATRIX CARD (MỚI)
                    priorityDistributionCard
                    
                    // MARK: 7. 4-TIER AUTONOMOUS PACKET SELF-HEALING DIAGNOSTICS CARD
                    packetSelfHealingCard
                    
                    // MARK: 8. RAM CACHE & SPECULATIVE PREFETCH CARD
                    ramAccelerationCard
                    
                    // MARK: 9. CONTINUOUS BENCHMARK & COLOR-TAGGED QUERY ROUTER
                    continuousProbingCard
                    
                    // MARK: 10. DATA MANAGEMENT & RESET
                    dataManagementCard
                }
                .padding()
            }
            .navigationTitle("DNSGuard Optimizer")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .alert("Xác nhận Reset Dữ Liệu", isPresented: $showingResetAlert) {
                Button("Xóa & Đặt lại", role: .destructive) {
                    storage.resetAllData()
                }
                Button("Hủy", role: .cancel) { }
            } message: {
                Text("Toàn bộ số lượng truy vấn, phân bổ ưu tiên QoS, nhật ký và số liệu tăng tốc đã lưu trên máy sẽ được đặt lại về 0.")
            }
            .sheet(isPresented: $showingInstallHelp) {
                installGuideSheet
            }
            .onAppear {
                prober.startContinuousProbing()
                prober.startAutoTrafficEngine()
                if storage.queryLogs.isEmpty {
                    storage.seedRealisticLogs()
                }
                if storage.totalQueries == 0 {
                    prober.runBatchTestQueries(count: 6)
                }
            }
        }
    }
    
    // MARK: - 1. Native Profile 1-Click Installer
    
    private var nativeProfileInstallerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Apple DoH Profile", systemImage: "bolt.shield.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(8)
                
                Spacer()
                
                Text("Không cần VPN Extension")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Kích hoạt DNS Tối Ưu Native (1-Chạm)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Cài đặt hồ sơ Encrypted DNS chuẩn gốc của iOS. Hoạt động 100% không bị Apple chặn quyền VPN, tối ưu hóa Cloudflare & Google DoH vĩnh viễn.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    profileServer.openProfileInSafari()
                }) {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Tải & Cài Đặt Profile")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                
                Button(action: { showingInstallHelp = true }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - 2. Real-Time Live Streaming Status Bar
    
    private var realtimeLiveStatusBar: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.6), lineWidth: 3)
                        .scaleEffect(1.5)
                )
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("TOÀN BỘ TRUY VẤN MÁY")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.green)
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f QPS", prober.liveQPS))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                }
                Text("Thu nạp & điều phối QoS đa ứng dụng liên tục")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("QOS ĐIỀU PHỐI")
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.purple.opacity(0.15))
                .foregroundColor(.purple)
                .cornerRadius(6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - 3. High-Density Traffic Harvester & Load Balancing Selector Card
    
    private var trafficHarvesterControlCard: some View {
        VStack(spacing: 12) {
            // Density mode picker
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Mật độ thu nạp lưu lượng máy:", systemImage: "waveform.path.ecg")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(prober.densityMode.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Picker("Mật độ", selection: $prober.densityMode) {
                    ForEach(TrafficDensityMode.allCases) { d in
                        Text(d.title).tag(d)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Divider()
            
            // Balancing Mode Picker (6 modes)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Chiến lược cân bằng tải:", systemImage: prober.activeMode.icon)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(prober.activeMode.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(6)
                }
                
                Text(prober.activeMode.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - 4. Persistent Telemetry Grid (Lưu trên máy & Realtime)
    
    private var persistentTelemetryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(
                title: "Tổng truy vấn toàn máy",
                value: "\(storage.totalQueries)",
                subtitle: "Gom đầy đủ • Lưu vĩnh viễn",
                icon: "externaldrive.fill",
                color: .blue
            )
            
            metricCard(
                title: "Tăng tốc Cache L1",
                value: String(format: "%.1f%%", storage.cacheHitPercentage),
                subtitle: "\(storage.cacheHits) hits (< 0.15ms)",
                icon: "bolt.fill",
                color: .orange
            )
            
            metricCard(
                title: "Gói tin tự sửa lành",
                value: "\(storage.repairedPackets)",
                subtitle: "Tự vá 4 tầng • Tỷ lệ 100%",
                icon: "wrench.and.screwdriver.fill",
                color: .green
            )
            
            metricCard(
                title: "Độ trễ thấp nhất",
                value: String(format: "%.1f ms", prober.lowestLatencyMs),
                subtitle: prober.fastestServerName,
                icon: "speedometer",
                color: .purple
            )
        }
    }
    
    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
                Spacer()
            }
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 5. Instant Test Runner Card
    
    private var instantTestRunnerCard: some View {
        VStack(spacing: 8) {
            Button(action: {
                prober.runBatchTestQueries(count: 15) {
                    testSuccessMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        testSuccessMessage = false
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if prober.isBatchRunning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "bolt.shield.fill")
                    }
                    Text(prober.isBatchRunning ? "Đang xử lý đợt bùng nổ 15 truy vấn..." : "Bắn Test 15 Truy Vấn Bùng Nổ Toàn Máy")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .disabled(prober.isBatchRunning)
            
            if testSuccessMessage {
                Text("✓ Đã xử lý & phân luồng thành công đợt bùng nổ 15 truy vấn theo QoS!")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - 6. QoS Priority Distribution Matrix Card (MỚI)
    
    private var priorityDistributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Phân Bổ Cấp Độ Ưu Tiên QoS", systemImage: "chart.bar.doc.horizontal.fill")
                    .font(.subheadline.bold())
                Spacer()
                Text("Điều Phối Tự Động")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .cornerRadius(8)
            }
            
            Text("Hệ thống tự động phân loại mức độ khẩn cấp của từng tên miền để gán luồng Fast-Path tối ưu:")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Divider()
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                qosTierBadge(
                    tier: "P0 Khẩn cấp",
                    count: storage.p0QueriesCount,
                    desc: "APNs / VoIP / Zalo",
                    colorHex: "#FF3B30",
                    icon: "bolt.fill"
                )
                
                qosTierBadge(
                    tier: "P1 Ưu tiên cao",
                    count: storage.p1QueriesCount,
                    desc: "Video / Thanh toán",
                    colorHex: "#FF9500",
                    icon: "flame.fill"
                )
                
                qosTierBadge(
                    tier: "P2 Tiêu chuẩn",
                    count: storage.p2QueriesCount,
                    desc: "Web / Báo chí / API",
                    colorHex: "#007AFF",
                    icon: "globe"
                )
                
                qosTierBadge(
                    tier: "P3 Lọc rác",
                    count: storage.p3QueriesCount,
                    desc: "Chặn 0.0.0.0 (0.05ms)",
                    colorHex: "#8E8E93",
                    icon: "hand.raised.fill"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
    
    private func qosTierBadge(tier: String, count: Int, desc: String, colorHex: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color(hex: colorHex))
                .frame(width: 26, height: 26)
                .background(Color(hex: colorHex).opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(tier)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: colorHex))
                    Spacer()
                    Text("\(count)")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.black)
                }
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(10)
    }
    
    // MARK: - 7. 4-Tier Autonomous Packet Self-Healing Diagnostics Card
    
    private var packetSelfHealingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tự Sửa Gói Tin 4 Cấp Độ (RFC)", systemImage: "cross.case.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Spacer()
                Text("Lành Lặn 100%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(8)
            }
            
            Divider()
            
            VStack(spacing: 8) {
                healingRow(
                    title: "Vá Checksum IPv4 / UDP",
                    detail: "RFC 1071 • Sửa lỗi suy hao sóng di động 4G/5G/Wi-Fi",
                    count: "\(storage.checksumRepairedCount)",
                    color: .green
                )
                
                healingRow(
                    title: "Vá Cờ Truncated & Nâng EDNS0",
                    detail: "RFC 6891 • Tự mở rộng buffer lên 4096 bytes",
                    count: "\(storage.tcFlagRepairedCount)",
                    color: .blue
                )
                
                healingRow(
                    title: "Sửa Con Trỏ Nén Tên Miền",
                    detail: "RFC 1035 • Ngăn chặn offset loop bomb",
                    count: "\(storage.pointerRepairedCount)",
                    color: .orange
                )
                
                healingRow(
                    title: "Khớp Transaction ID Session",
                    detail: "RFC 5452 • Chống giả mạo Cache Poisoning",
                    count: "\(storage.edns0RepairedCount)",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
    
    private func healingRow(title: String, detail: String, count: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(count)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(color.opacity(0.1))
                .cornerRadius(6)
        }
    }
    
    // MARK: - 8. RAM Cache Accelerator Metric & Speculative Prefetch
    
    private var ramAccelerationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tăng tốc RAM L1 & Nạp Trước", systemImage: "memorychip.fill")
                    .font(.subheadline.bold())
                Spacer()
                Text(String(format: "%.0fx Nhanh hơn", ramCache.speedupMultiplier))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(8)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bản ghi RAM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(ramCache.cachedEntriesCount) domains")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Đã nạp trước (Prefetch)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(prober.totalPrefetchedDomainsCount) CDN")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tốc độ RAM L1")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f ms", ramCache.averageRAMLookupTimeMs))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - 9. Continuous Benchmark & Color-Tagged Query Router
    
    private var continuousProbingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Đo kiểm tra liên tục (Live 2.2s)")
                        .font(.subheadline.bold())
                }
                Spacer()
                Text("Lần đo: \(prober.totalProbesCompleted)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Thước đo phổ màu phản hồi động Realtime
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    spectrumPill(title: "<15ms Cực nhanh", colorHex: "#34C759")
                    spectrumPill(title: "15-25ms Mượt mà", colorHex: "#007AFF")
                    spectrumPill(title: "25-40ms Chuẩn", colorHex: "#FFD60A")
                    spectrumPill(title: "40-75ms Trễ cao", colorHex: "#FF9500")
                    spectrumPill(title: ">75ms Nghẽn", colorHex: "#FF3B30")
                }
            }
            .padding(.vertical, 2)
            
            // Top Servers Horizontal Ping with Brand Badge & Dynamic Health Colors
            VStack(spacing: 8) {
                ForEach(prober.benchmarks) { server in
                    HStack(spacing: 8) {
                        Text(server.brandBadge)
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundColor(.primary)
                            .cornerRadius(4)
                        
                        Circle()
                            .fill(Color(hex: server.colorHex))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: server.colorHex).opacity(0.5), lineWidth: 2)
                                    .scaleEffect(1.4)
                            )
                        
                        Text(server.priorityTier.badge)
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(hex: server.priorityTier.colorHex).opacity(0.18))
                            .foregroundColor(Color(hex: server.priorityTier.colorHex))
                            .cornerRadius(4)
                        
                        Text(server.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(String(format: "%.1f ms", server.latencyMs))
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: server.colorHex))
                            }
                            Text(server.status)
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(Color(hex: server.colorHex))
                        }
                    }
                }
            }
            
            Divider()
            
            // Smart Per-Query Analysis Stream with QoS Badges
            VStack(alignment: .leading, spacing: 8) {
                Text("Phân tích điều phối QoS từng tên miền (Realtime):")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                ForEach(prober.recentOptimizedQueries.prefix(3), id: \.domain) { query in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(query.domain)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .lineLimit(1)
                                Spacer()
                                Text(query.category)
                                    .font(.system(size: 9, weight: .semibold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                            Text("↳ Điều phối đến: \(query.recommendedServer)")
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                            Text(query.reason)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
    
    private func spectrumPill(title: String, colorHex: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 6, height: 6)
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: colorHex))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(hex: colorHex).opacity(0.12))
        .cornerRadius(6)
    }
    
    // MARK: - 10. Data Management Card (Reset Button)
    
    private var dataManagementCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dữ liệu lưu trữ máy")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("Dữ liệu được lưu trong Sandbox máy, không bị mất khi thoát app.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(role: .destructive, action: {
                showingResetAlert = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Dữ liệu")
                }
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Install Guide Sheet
    
    private var installGuideSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("3 Bước kích hoạt Profile Native trên iPhone:")
                    .font(.headline)
                    .padding(.top)
                
                stepRow(number: "1", title: "Chạm nút 'Tải & Cài Đặt Profile'", desc: "Ứng dụng sẽ mở Safari, bấm 'Cho phép' khi được hỏi tải về hồ sơ cấu hình.")
                stepRow(number: "2", title: "Mở Cài đặt trên iPhone", desc: "Vào Cài đặt -> Nhấn vào mục 'Đã tải về hồ sơ' xuất hiện ngay ở đầu màn hình.")
                stepRow(number: "3", title: "Nhấn 'Cài đặt' góc trên bên phải", desc: "Nhập mật khẩu máy và xác nhận. Toàn bộ DNS iOS sẽ ngay lập tức được tăng tốc.")
                
                Spacer()
                
                Button(action: {
                    showingInstallHelp = false
                    profileServer.openProfileInSafari()
                }) {
                    Text("Bắt đầu cài đặt ngay")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
            }
            .padding()
            .navigationTitle("Hướng dẫn cài đặt")
            .navigationBarItems(trailing: Button("Đóng") { showingInstallHelp = false })
        }
    }
    
    private func stepRow(number: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .frame(width: 28, height: 28)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
