//
//  DashboardView.swift
//  DNSGuard
//
//  Created for iOS Local DNS Optimizer.
//  Integrated with 1-Click Native MobileConfig Installer, Continuous Prober,
//  Persistent On-Device Storage, RAM Cache Accelerator, and Sub-Second Real-Time Streaming.
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
                    
                    // MARK: 2. REAL-TIME LIVE STREAMING STATUS BAR
                    realtimeLiveStatusBar
                    
                    // MARK: 3. ACTIVE ACCELERATION & BALANCING MODE SELECTOR
                    activeEngineControlCard
                    
                    // MARK: 4. PERSISTENT TELEMETRY GRID (Lưu trên máy & Realtime)
                    persistentTelemetryGrid
                    
                    // MARK: 5. 1-CLICK INSTANT TEST RUNNER (Bắn test tức thì)
                    instantTestRunnerCard
                    
                    // MARK: 6. RAM CACHE ACCELERATOR METRIC (Tăng tốc bằng RAM)
                    ramAccelerationCard
                    
                    // MARK: 7. CONTINUOUS BENCHMARK & SMART QUERY ROUTER
                    continuousProbingCard
                    
                    // MARK: 8. DATA MANAGEMENT & RESET
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
                Text("Toàn bộ số lượng truy vấn, nhật ký và số liệu tăng tốc đã lưu trên máy sẽ được đặt lại về 0.")
            }
            .sheet(isPresented: $showingInstallHelp) {
                installGuideSheet
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
                    Text("REALTIME LIVE STREAM")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.green)
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f QPS", prober.liveQPS))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                }
                Text("Dữ liệu tự động cập nhật thời gian thực mỗi 1.2s")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("ĐANG CHẠY")
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.15))
                .foregroundColor(.green)
                .cornerRadius(6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - 3. Active Engine & Load Balancing Selector Card
    
    private var activeEngineControlCard: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cpu.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Động cơ Tự Động Điều Phối Nền")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text(prober.isAutoTrafficActive ? "Đang xử lý & phân luồng lưu lượng liên tục" : "Tạm dừng xử lý nền")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Toggle("", isOn: $prober.isAutoTrafficActive)
                    .labelsHidden()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
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
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(6)
                }
                
                Picker("Chiến lược", selection: $prober.activeMode) {
                    ForEach(DNSLoadBalancingMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
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
                title: "Tổng truy vấn",
                value: "\(storage.totalQueries)",
                subtitle: "Realtime • Đã lưu trên máy",
                icon: "externaldrive.fill",
                color: .blue
            )
            
            metricCard(
                title: "Tăng tốc Cache",
                value: String(format: "%.1f%%", storage.cacheHitPercentage),
                subtitle: "\(storage.cacheHits) hits (< 0.2ms)",
                icon: "bolt.fill",
                color: .orange
            )
            
            metricCard(
                title: "Gói tin tự sửa",
                value: "\(storage.repairedPackets)",
                subtitle: "Vá Checksum & cờ TC",
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
                prober.runBatchTestQueries(count: 10) {
                    testSuccessMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        testSuccessMessage = false
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if prober.isBatchRunning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "play.circle.fill")
                    }
                    Text(prober.isBatchRunning ? "Đang bắn kiểm tra 10 truy vấn..." : "Bắn Test 10 Truy Vấn DNS Ngay Lập Tức")
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
                Text("✓ Đã xử lý & cập nhật tức thì 10 truy vấn vào bảng điều khiển và nhật ký!")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - 6. RAM Cache Accelerator Metric
    
    private var ramAccelerationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tăng tốc bằng RAM thiết bị", systemImage: "memorychip.fill")
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
                    Text("RAM cấp phát")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f MB", ramCache.estimatedRAMUsageMB))
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bản ghi trong RAM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(ramCache.cachedEntriesCount) domains")
                        .font(.headline)
                        .fontWeight(.bold)
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
    
    // MARK: - 7. Continuous Probing & Smart Query Analysis
    
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
            
            // Top Servers Horizontal Ping
            VStack(spacing: 8) {
                ForEach(prober.benchmarks.prefix(4)) { server in
                    HStack {
                        Text(server.name)
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Tải \(String(format: "%.0f%%", server.loadPercentage))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.blue)
                        Text(String(format: "%.1f ms", server.latencyMs))
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(server.latencyMs < 18 ? .green : .orange)
                            .frame(width: 55, alignment: .trailing)
                    }
                }
            }
            
            Divider()
            
            // Smart Per-Query Analysis Stream
            VStack(alignment: .leading, spacing: 8) {
                Text("Phân tích từng truy vấn theo Server tối ưu (Realtime):")
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
    
    // MARK: - 8. Data Management Card (Reset Button)
    
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
